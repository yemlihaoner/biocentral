import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../util/biocentral_exception.dart';
import '../util/constants.dart';
import '../util/logging.dart';
import '../util/type_util.dart';
import 'biocentral_server_data.dart';
import 'biocentral_service_api.dart';

@immutable
class DownloadProgress {
  final int bytesReceived;
  final int? totalBytes;
  final double? progress;
  final Uint8List bytes;

  const DownloadProgress(this.bytesReceived, this.totalBytes, this.bytes)
      : progress = totalBytes != null ? bytesReceived / totalBytes : null;

  bool isDone() {
    return totalBytes == null ? false : bytesReceived == totalBytes;
  }
}

final class _BiocentralClientSandbox {
  static Either<BiocentralException, Map> _handleServerResponse(Response response) {
    if (response.statusCode != 200) {
      if (response.statusCode >= 500) {
        return left(BiocentralServerException(
            message: "An error on the server happened, Status Code: ${response.statusCode} "
                "- Reason: ${response.reasonPhrase}"));
      }
      return left(BiocentralNetworkException(
          message:
              "A networking error happened, Status Code: ${response.statusCode} - Reason: ${response.reasonPhrase}"));
    }
    Map? responseMap = jsonDecode(response.body);
    if (responseMap == null) {
      return left(
          BiocentralParsingException(message: "Could not parse response body to json! Response: ${response.body}"));
    }
    String? error = responseMap["error"];
    if (error != null) {
      return left(BiocentralServerException(message: "An error on the server happened!", error: error));
    }
    return right(responseMap);
  }

  static Future<Either<BiocentralException, Map>> doGetRequest(String url, String endpoint) async {
    try {
      Uri uri = Uri.parse(url + endpoint);
      Response response = await http.get(uri);
      return _handleServerResponse(response);
    } catch (e, stackTrace) {
      return left(BiocentralNetworkException(
          message: "Error for GET Request at $url$endpoint", error: e, stackTrace: stackTrace));
    }
  }

  /// Test the server at [url] against the specified [endpoint]
  ///
  /// In contrast to [doGetRequest], this method does not throw an error if the connection cannot be established,
  /// but an empty map
  static Future<Map> isServerUp(String url, String endpoint) async {
    try {
      Uri uri = Uri.parse(url + endpoint);
      Response response = await http.get(uri);
      if (response.statusCode != 200) {
        return {};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {};
    }
  }

  static Future<Either<BiocentralException, Map>> doPostRequest(
      String url, String endpoint, Map<String, String> body) async {
    try {
      Uri uri = Uri.parse(url + endpoint);
      Map<String, String> headers = {"Content-Type": "application/json"};
      Response response = await http.post(uri, headers: headers, body: json.encode(body));
      return _handleServerResponse(response);
    } catch (e, stackTrace) {
      return left(BiocentralNetworkException(
          message: "Error for POST Request at $url$endpoint", error: e, stackTrace: stackTrace));
    }
  }

  static Future<Either<BiocentralException, Uint8List>> downloadFile(String url) async {
    try {
      Uri uri = Uri.parse(url);
      Response response = await http.get(uri);

      if (response.statusCode != 200) {
        return left(
            BiocentralNetworkException(message: "Failed to download file. Status code: ${response.statusCode}"));
      }
      final Uint8List downloadedBytes = response.bodyBytes;

      if (downloadedBytes.isEmpty) {
        return left(BiocentralNetworkException(message: "Downloaded file is empty!"));
      }

      return right(downloadedBytes);
    } catch (e, stackTrace) {
      return left(
          BiocentralNetworkException(message: "Error downloading file from $url", error: e, stackTrace: stackTrace));
    }
  }

  static Stream<Either<BiocentralException, DownloadProgress>> downloadFileWithProgress(String url) async* {
    int? totalBytes;

    try {
      Uri uri = Uri.parse(url);

      // Try to get the file size with a HEAD request
      final headResponse = await http.head(uri);
      if (headResponse.statusCode == 200) {
        totalBytes = int.tryParse(headResponse.headers['content-length'] ?? '');
      }

      final request = http.Request('GET', uri);
      final response = await request.send();

      if (response.statusCode != 200) {
        yield left(
            BiocentralNetworkException(message: "Failed to start download. Status code: ${response.statusCode}"));
        return;
      }

      // If we didn't get the size from HEAD, try to get it from GET
      totalBytes ??= response.contentLength;

      int received = 0;

      await for (final chunk in response.stream) {
        received += chunk.length;

        yield right(DownloadProgress(received, totalBytes, Uint8List.fromList(chunk)));
      }
      // Empty last chunk to indicate that download is done
      yield right(DownloadProgress(received, received, Uint8List.fromList([])));
    } catch (e, stackTrace) {
      yield left(
          BiocentralNetworkException(message: "Error downloading file from $url", error: e, stackTrace: stackTrace));
    }
  }
}

abstract class BiocentralClient {
  final BiocentralServerData? _server;

  BiocentralClient(this._server);

  String getServiceName();

  Either<BiocentralException, String> _getBaseURL() {
    if (_server == null) {
      return left(BiocentralNetworkException(message: "Not connected to any server to perform request!"));
    }
    return right(_server!.url);
  }

  Future<Either<BiocentralException, Map>> doGetRequest(String endpoint) async {
    final urlEither = _getBaseURL();
    return urlEither.match((l) => left(l), (url) => _BiocentralClientSandbox.doGetRequest(url, endpoint));
  }

  Future<Either<BiocentralException, Map>> doPostRequest(String endpoint, Map<String, String> body) async {
    final urlEither = _getBaseURL();
    return urlEither.match((l) => left(l), (url) => _BiocentralClientSandbox.doPostRequest(url, endpoint, body));
  }

  Future<Either<BiocentralException, Unit>> transferFile(
      String databaseHash, StorageFileType fileType, Future<String> Function() databaseConversionFunction) async {
    // Check if hash exists
    final responseEither =
        await doGetRequest("${BiocentralServiceEndpoints.hashesEndpoint}$databaseHash/${fileType.name}");
    return responseEither.match((l) => left(l), (responseMap) async {
      bool hashExists = responseMap[databaseHash] ?? false;
      if (hashExists) {
        logger.i("Found file type $fileType for $databaseHash on server, file is not transferred!");
        return right(unit);
      } else {
        String convertedDatabase = await databaseConversionFunction();

        if (convertedDatabase.isEmpty) {
          // Nothing to send
          return right(unit);
        }

        final transferResponseEither = await doPostRequest(BiocentralServiceEndpoints.transferFileEndpoint,
            {"hash": databaseHash, "file_type": fileType.name, "file": convertedDatabase});
        return transferResponseEither.match((e) => left(e), (r) {
          logger.i("File type $fileType was transferred for database hash $databaseHash!");
          return right(unit);
        });
      }
    });
  }

  List<String> responseStringToList(String responseBody) {
    //TODO Use json decode?
    responseBody = responseBody.replaceAll("[", "");
    responseBody = responseBody.replaceAll("]", "");
    responseBody = responseBody.replaceAll("\"", "");
    responseBody = responseBody.replaceAll("\n", "");
    return responseBody.split(",");
  }
}

abstract class BiocentralClientFactory<T extends BiocentralClient> {
  T create(BiocentralServerData? server);

  Type getClientType() {
    return T;
  }
}

class ClientManager {
  final Map<Type, BiocentralClientFactory> _factories = {};
  final Map<Type, BiocentralClient> _clients = {};

  BiocentralServerData? _server;

  void registerFactory(BiocentralClientFactory factory) {
    _factories[factory.getClientType()] = factory;
  }

  void setServer(BiocentralServerData? server) {
    _server = server;
    _clients.clear();
  }

  T getClient<T extends BiocentralClient>() {
    if (!_clients.containsKey(T)) {
      final factory = _factories[T];
      if (factory == null) {
        throw Exception("No factory registered for $T");
      }
      _clients[T] = factory.create(_server);
    }
    return _clients[T] as T;
  }

  bool isServiceAvailable<T extends BiocentralClient>() {
    return _factories.containsKey(T);
  }
}

final class BiocentralClientRepository {
  final ClientManager _clientManager = ClientManager();

  BiocentralClientRepository.withReload(BiocentralClientRepository? old) {
    _clientManager.setServer(old?._clientManager._server);
  }

  void registerServices(List<BiocentralClientFactory> factories) {
    for (BiocentralClientFactory factory in factories) {
      _clientManager.registerFactory(factory);
    }
  }

  Future<Set<BiocentralServerData>> getAvailableServers() async {
    // TODO Connect to master server and get actual list
    final services = await checkServerStatus(Constants.localHostServerURL);
    if (services.isEmpty) {
      return {};
    }
    return {BiocentralServerData.local(availableServices: services)};
  }

  Future<List<String>> checkServerStatus(String url) async {
    final serviceMap = await _BiocentralClientSandbox.isServerUp(url, BiocentralServiceEndpoints.servicesEndpoint);
    return List<String>.from(serviceMap["services"] ?? {});
  }

  Future<Either<BiocentralException, Unit>> connectToServer(BiocentralServerData server) async {
    final services = await checkServerStatus(server.url);
    if (services.isEmpty) {
      return left(BiocentralServerException(message: "The server does not provide any services!"));
    }
    _clientManager.setServer(server);
    logger.i("Connected to biocentral server with services: ${server.availableServices}");
    return right(unit);
  }

  Future<Either<BiocentralException, Map<String, String>>> _getLatestReleaseDownloadUrl(
      String owner, String repo, Set<String> osNames) async {
    final url = Uri.parse("https://api.github.com/repos/$owner/$repo/releases/latest");

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assets = data["assets"] as List;

        final Map<String, String> result = {};

        for (var asset in assets) {
          for (String osName in osNames) {
            if (asset["name"].toString().contains(osName)) {
              result[osName] = asset["browser_download_url"];
              break;
            }
          }
        }

        if (result.isEmpty) {
          return left(BiocentralIOException(message: "Could not find any biocentral_server releases!"));
        }
        return right(result);
      } else {
        return left(BiocentralNetworkException(
            message: "Failed to fetch latest biocentral_server release: ${response.statusCode}"));
      }
    } catch (e) {
      return left(BiocentralNetworkException(message: "Failed to fetch latest biocentral_server release", error: e));
    }
  }

  Future<Either<BiocentralException, Map<String, String>>> getLocalServerDownloadURLs() async {
    // TODO Maybe change back to download from server
    const String serverReleasesJsonURL = "assets/server_releases/biocentral_server_releases.json";
    String releaseFileContent = await rootBundle.loadString(serverReleasesJsonURL);
    Map<String, String> releaseMap = stringMapFromJsonDecode(jsonDecode(releaseFileContent));
    return right(releaseMap);

    // final downloadEither = await _BiocentralClientSandbox.downloadFile(serverReleasesJsonURL);
    // return downloadEither.flatMap((downloadedBytes) {
    //   final jsonFile = String.fromCharCodes(downloadedBytes);
    //   Map<String, String> releaseMap = stringMapFromJsonDecode(jsonDecode(jsonFile));
    //   return right(releaseMap);
    // });
  }

  Stream<Either<BiocentralException, DownloadProgress>> downloadServerRelease(String url) async* {
    yield* _BiocentralClientSandbox.downloadFileWithProgress(url);
  }

  bool isServiceAvailable<T extends BiocentralClient>() {
    return _clientManager.isServiceAvailable<T>();
  }

  T getServiceClient<T extends BiocentralClient>() {
    return _clientManager.getClient<T>();
  }
}
