import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'dart:ui';
import 'package:http/http.dart' as http;

class Material {
  Material()
      : name = '',
        ambient = Vector3.all(0.1),
        diffuse = Vector3.all(0.8),
        specular = Vector3.all(0.5),
        ke = Vector3.zero(),
        tf = Vector3.zero(),
        mapKa = '',
        mapKd = '',
        mapKe = '',
        shininess = 0,
        ni = 0,
        opacity = 1.0,
        illum = 0;
  String name;
  Vector3 ambient;
  Vector3 diffuse;
  Vector3 specular;
  Vector3 ke;
  Vector3 tf;
  double shininess;
  double ni;
  double opacity;
  int illum;
  String mapKa;
  String mapKd;
  String mapKe;
}

/// Loading material from Material Library File (.mtl).
/// Reference：http://paulbourke.net/dataformats/mtl/
///
Future<Map<String, Material>> loadMtl(String fileName,
    {bool isAsset = true, String? url}) async {
  final materials = <String, Material>{};
  String data;
  try {
    if (url != null) {
      if (url.endsWith("/") == false) {
        url = "$url/";
      }
      http.Client client = http.Client();
      var req = await client.get(Uri.parse(url + fileName));
      data = req.body;
    } else if (isAsset) {
      data = await rootBundle.loadString(fileName);
    } else {
      data = await File(fileName).readAsString();
    }
  } catch (_) {
    return materials;
  }
  final List<String> lines = data.split('\n');

  Material material = Material();
  for (String line in lines) {
    List<String> parts = line.trim().split(RegExp(r"\s+"));
    switch (parts[0]) {
      case 'newmtl':
        material = Material();
        if (parts.length >= 2) {
          material.name = parts[1];
          materials[material.name] = material;
        }
        break;
      case 'Ka':
        if (parts.length >= 4) {
          final v = Vector3(double.parse(parts[1]), double.parse(parts[2]),
              double.parse(parts[3]));
          material.ambient = v;
        }
        break;
      case 'Kd':
        if (parts.length >= 4) {
          final v = Vector3(double.parse(parts[1]), double.parse(parts[2]),
              double.parse(parts[3]));
          material.diffuse = v;
        }
        break;
      case 'Ks':
        if (parts.length >= 4) {
          final v = Vector3(double.parse(parts[1]), double.parse(parts[2]),
              double.parse(parts[3]));
          material.specular = v;
        }
        break;
      case 'Ke':
        if (parts.length >= 4) {
          final v = Vector3(double.parse(parts[1]), double.parse(parts[2]),
              double.parse(parts[3]));
          material.ke = v;
        }
        break;
      case 'map_Ka':
        if (parts.length >= 2) {
          material.mapKa = parts.last;
        }
        break;
      case 'map_Kd':
        if (parts.length >= 2) {
          material.mapKd = parts.last;
        }
        break;
      case 'Ns':
        if (parts.length >= 2) {
          material.shininess = double.parse(parts[1]);
        }
        break;
      case 'Ni':
        if (parts.length >= 2) {
          material.ni = double.parse(parts[1]);
        }
        break;
      case 'd':
        if (parts.length >= 2) {
          material.opacity = double.parse(parts[1]);
        }
        break;
      case 'illum':
        if (parts.length >= 2) {
          material.illum = int.parse(parts[1]);
        }
        break;
      default:
    }
  }
  return materials;
}

/// load an image from url
Future<Image> loadImageFromUrl(String fileName) async {
  final c = Completer<Image>();
  Uint8List dataFuture;
  http.Client client = http.Client();
  var req = await client.get(Uri.parse(fileName));
  dataFuture = req.bodyBytes.buffer.asUint8List();
  try {
    instantiateImageCodec(dataFuture).then((codec) {
      codec.getNextFrame().then((frameInfo) {
        c.complete(frameInfo.image);
      });
    });
  } catch (error) {
    c.completeError(error);
  }

  return c.future;
}

/// load an image from asset
Future<Image> loadImageFromAsset(String fileName, {bool isAsset = true}) {
  final c = Completer<Image>();
  Future<Uint8List> dataFuture;
  if (isAsset) {
    dataFuture =
        rootBundle.load(fileName).then((data) => data.buffer.asUint8List());
  } else {
    dataFuture = File(fileName).readAsBytes();
  }
  dataFuture.then((data) {
    instantiateImageCodec(data).then((codec) {
      codec.getNextFrame().then((frameInfo) {
        c.complete(frameInfo.image);
      });
    });
  }).catchError((error) {
    c.completeError(error);
  });
  return c.future;
}

/// load texture from asset
Future<MapEntry<String, Image>?> loadTexture(
    Material? material, String basePath,
    {bool isAsset = true, String? url}) async {
  // get the texture file name
  if (material == null) return null;
  String fileName = material.mapKa;
  if (fileName == '') fileName = material.mapKd;
  if (fileName == '') return null;

  Image? image;

  // load image from url
  if (url != null) {
    if (url.endsWith("/") == false) {
      url = "$url/";
    }
    image = await loadImageFromUrl(url + fileName);
    return MapEntry(fileName, image);
  } else {
    // try to load image from asset in subdirectories
    final List<String> dirList = fileName.split(RegExp(r'[/\\]+'));
    while (dirList.isNotEmpty) {
      fileName = path.join(basePath, path.joinAll(dirList));
      try {
        image = await loadImageFromAsset(fileName, isAsset: isAsset);
      } catch (_) {}
      if (image != null) return MapEntry(fileName, image);
      dirList.removeAt(0);
    }
  }

  return null;
}

Future<Uint32List> getImagePixels(Image image) async {
  final c = Completer<Uint32List>();
  image.toByteData(format: ImageByteFormat.rawRgba).then((data) {
    c.complete(data!.buffer.asUint32List());
  }).catchError((error) {
    c.completeError(error);
  });

  return c.future;
}

/// Convert Vector3 to Color
Color toColor(Vector3 v, [double opacity = 1.0]) {
  return Color.fromRGBO(
      (v.r * 255).toInt(), (v.g * 255).toInt(), (v.b * 255).toInt(), opacity);
}

/// Convert Color to Vector3
Vector3 fromColor(Color color) {
  return Vector3(color.r / 255, color.g / 255, color.b / 255);
}
