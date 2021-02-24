import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/utils/util.dart';

class Item extends StatelessWidget {
  final Country country;
  final bool showFlag;
  final bool showCode;
  final bool useEmoji;
  final TextStyle textStyle;
  final bool withCountryNames;
  final BoxShape shape;

  const Item({
    Key key,
    this.country,
    this.showFlag,
    this.showCode,
    this.useEmoji,
    this.textStyle,
    this.shape = BoxShape.circle,
    this.withCountryNames = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _Flag(
              country: country,
              showFlag: showFlag,
              useEmoji: useEmoji,
              shape: shape),
          SizedBox(width: 12.0),
          (showCode)
              ? Text(
                  '${(country?.dialCode ?? '').padRight(5, "   ")}',
                  textDirection: TextDirection.ltr,
                  style: textStyle,
                )
              : Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF12326B),
                ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final Country country;
  final bool showFlag;
  final bool useEmoji;
  final BoxShape shape;

  const _Flag({Key key, this.country, this.showFlag, this.shape, this.useEmoji})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return country != null && showFlag
        ? Container(
            child: useEmoji
                ? Text(
                    Utils.generateFlagEmojiUnicode(country?.alpha2Code ?? ''),
                    style: Theme.of(context).textTheme.headline5,
                  )
                : country?.flagUri != null
                    ? shape == BoxShape.rectangle
                        ? Container(
                            height: 16,
                            width: 24,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(country?.flagUri,
                                        package: 'intl_phone_number_input'),
                                    fit: BoxFit.fitWidth)))
                        : CircleAvatar(
                            radius: 16,
                            backgroundImage: AssetImage(
                              country?.flagUri,
                              package: 'intl_phone_number_input',
                            ),
                          )
                    : SizedBox.shrink(),
          )
        : SizedBox.shrink();
  }
}

