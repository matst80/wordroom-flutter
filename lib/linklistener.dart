import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

enum UniLinksType { string, uri }

abstract class LinkListener<T extends StatefulWidget> extends State<T> {
  UniLinksType _type = UniLinksType.string;

  startLinkListeners() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    } else {
      await initPlatformStateForUriUniLinks();
    }
  }

  void parseLink(String link) {
    if (link == null || link.isEmpty) return;
    processLink(link);
  }

  void processLink(String link);

  initPlatformStateForStringUniLinks() async {
    getLinksStream().listen((String link) {
      parseLink(link);
    }, onError: (err) {
      print('got err: $err');
    });

    try {
      var initialLink = await getInitialLink();
      parseLink(initialLink);
    } on PlatformException {
      print('got platformerror');
    } on FormatException {
      print('got formaterror');
    }
  }

  initPlatformStateForUriUniLinks() async {
    getUriLinksStream().listen((Uri uri) {
      parseLink(uri.toString());
    }, onError: (err) {
      print('got err: $err');
    });

    try {
      var initialUri = await getInitialUri();
      parseLink(initialUri.toString());
    } on PlatformException {
      print('got platformerror');
    } on FormatException {
      print('got formaterror');
    }
  }
}
