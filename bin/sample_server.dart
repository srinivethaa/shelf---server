import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;

void main(List<String> arguments) async {
  final List data = json.decode(File('data.json').readAsStringSync());

  final app = Router();

  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type',
  };

  app.get(
    '/data/<email>/<password>',
    (
      Request req,
      String email,
      String password,
    ) {
      validationEnum validationStatus;
      var validation = data.firstWhere(
        (element) {
          var validated;
          if (element['email'] == email && element['password'] == password) {
            validationStatus = validationEnum.success;
            validated = true;
          } else if (element['email'] != email &&
              element['password'] == password) {
            validationStatus = validationEnum.invalidEmail;
            validated = false;
          } else if (element['email'] == email &&
              element['password'] != password) {
            validationStatus = validationEnum.invalidPassword;
            validated = false;
          } else {
            validationStatus = validationEnum.failed;
            validated = false;
          }
          return validated;
        },
        orElse: () => false,
      );
      if (validation != null) {
        if (validationStatus == validationEnum.success) {
          return Response.ok(
            'Credentials found and matched successfully!',
            headers: {
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
          );
        } else if (validationStatus == validationEnum.invalidEmail) {
          return Response.ok(
            'Email address not found or Incorrect email address!',
            headers: {
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
          );
        } else if (validationStatus == validationEnum.invalidPassword) {
          return Response.ok(
            'Incorrect password!',
            headers: {
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
          );
        } else {
          return Response.ok(
            'Invalid Credentials!',
            headers: {
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
          );
        }
      } else {
        return Response.notFound(
          'Authentication failed, email address not found!',
        );
      }
    },
  );

  // Set CORS headers with every request
  final handler = Pipeline().addMiddleware((innerHandler) {
    return (request) async {
      final response = await innerHandler(request);
      print(request.headers);

      // Set CORS when responding to OPTIONS request
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      // Move onto handler
      return response;
    };
  }).addHandler(app);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Serving at http://${server.address.host}:${server.port}');
}

enum validationEnum {
  invalidEmail,
  invalidPassword,
  success,
  failed,
}
