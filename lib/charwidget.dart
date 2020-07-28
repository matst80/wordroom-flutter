import 'package:flutter/material.dart';

class CharWidget extends StatelessWidget {
  CharWidget(
      {@required this.char,
      this.taken,
      this.selected,
      this.highlighted,
      this.onLongPress});

  final String char;
  final bool taken;
  final bool selected;
  final bool highlighted;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: taken
                ? Colors.transparent
                : highlighted
                    ? Colors.lightGreen
                    : selected ? Colors.purpleAccent : Colors.purple,
            border: Border.all(
                style: taken ? BorderStyle.none : BorderStyle.solid,
                color: selected ? Colors.purpleAccent : Colors.white,
                width: 3),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            boxShadow: taken
                ? []
                : [
                    BoxShadow(
                        offset: Offset(1, 1),
                        blurRadius: 1,
                        spreadRadius: 0,
                        color: Colors.black54)
                  ]),
        margin: EdgeInsets.all(selected ? 7 : 2),
        child: GestureDetector(
          onLongPress: () {
            onLongPress?.call();
          },
            child: Center(
                child: Text(taken ? '' : char.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 27)))));
  }
}
