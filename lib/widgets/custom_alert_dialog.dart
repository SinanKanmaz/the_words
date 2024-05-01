import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String? title;
  final String? body;
  final String? acceptText;
  final String? rejectText;
  final VoidCallback? accept;
  final VoidCallback? reject;

  const CustomAlertDialog(
      {Key? key,
      this.title,
      this.body,
      this.accept,
      this.reject,
      this.acceptText,
      this.rejectText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return buildAlertDialog();
    } else {
      if (Platform.isIOS || Platform.isMacOS) {
        return CupertinoAlertDialog(
          title: title != null ? Text(title!) : null,
          content: body != null ? Text(body!) : null,
        );
      } else {
        return buildAlertDialog();
      }
    }
  }

  AlertDialog buildAlertDialog() {
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: body != null ? Text(body!) : null,
      actions: [
        if (accept != null)
          TextButton(
            onPressed: accept,
            child: Text(acceptText!),
          ),
        if (reject != null)
          TextButton(
            onPressed: reject,
            child: Text(rejectText!),
          ),
      ],
    );
  }
}
