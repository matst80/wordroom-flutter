import 'package:flutter/material.dart';

class CharWidget extends StatelessWidget {
  CharWidget(
      {@required this.char,
      this.taken,
      this.selected,
      this.highlighted,
      this.onLongPress,
      this.wordColor});

  final String char;
  final Color wordColor;
  final bool taken;
  final bool selected;
  final bool highlighted;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: taken
              ? Colors.pinkAccent.withAlpha(0)
              : highlighted || selected
                  ? Colors.pinkAccent
                  : wordColor ?? Colors.pink,
          border: Border.all(
              style: taken ? BorderStyle.none : BorderStyle.solid,
              color: selected
                  ? Colors.white.withAlpha(150)
                  : Colors.white.withAlpha(250),
              width: 2),
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
        ),
        margin: EdgeInsets.all(selected ? 7 : 2),
        child: GestureDetector(
            onLongPress: () {
              onLongPress?.call();
            },
            child: Center(
                child: Text(taken ? '' : char.toUpperCase(),
                    style: TextStyle(
                        shadows: [
                          Shadow(
                            blurRadius: 6.0,
                            color: Colors.black.withAlpha(180),
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                        color: selected || highlighted
                            ? Colors.white
                            : Colors.white,
                        fontSize: 32)))));
  }
}
