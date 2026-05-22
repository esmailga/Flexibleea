import 'package:flutter/material.dart';

class GlobalMethod {
  static void showErrorDialog(
      {required BuildContext ctx, required String error}) {
    showDialog(
        context: ctx,
        builder: (context) {
          return AlertDialog(
            title: const Row(children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.logout,
                  color: Colors.black,
                  size: 35,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Error occured',
                ),
              ),
            ]),
            content: Text(
              error,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 20,
                  fontStyle: FontStyle.italic),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.canPop(context) ? Navigator.pop(context) : null;
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.amber),
                  ))
            ],
          );
        });
  }
}
