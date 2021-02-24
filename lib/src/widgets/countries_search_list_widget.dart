import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input/src/utils/util.dart';

class CountrySearchListWidget extends StatefulWidget {
  final List<Country> countries;
  final InputDecoration searchBoxDecoration;
  final String locale;
  final ScrollController scrollController;
  final bool autoFocus;
  final bool showFlags;
  final bool useEmoji;
  final BoxShape shape;

  CountrySearchListWidget(this.countries, this.locale,
      {this.searchBoxDecoration,
      this.scrollController,
      this.showFlags,
      this.useEmoji,
      this.shape = BoxShape.circle,
      this.autoFocus = false});

  @override
  _CountrySearchListWidgetState createState() =>
      _CountrySearchListWidgetState();
}

class _CountrySearchListWidgetState extends State<CountrySearchListWidget> {
  TextEditingController _searchController = TextEditingController();
  List<Country> filteredCountries;

  @override
  void initState() {
    filteredCountries = filterCountries();
    super.initState();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  InputDecoration getSearchBoxDecoration() {
    return widget.searchBoxDecoration ??
        InputDecoration(labelText: 'Search by country name or dial code');
  }

  List<Country> filterCountries() {
    final value = _searchController.text.trim();

    if (value.isNotEmpty) {
      return widget.countries
          .where(
            (Country country) =>
                country.alpha3Code
                    .toLowerCase()
                    .startsWith(value.toLowerCase()) ||
                country.name.toLowerCase().contains(value.toLowerCase()) ||
                getCountryName(country)
                    .toLowerCase()
                    .contains(value.toLowerCase()) ||
                country.dialCode.contains(value.toLowerCase()),
          )
          .toList();
    }

    return widget.countries;
  }

  String getCountryName(Country country) {
    if (widget.locale != null && country.nameTranslations != null) {
      String translated = country.nameTranslations[widget.locale];
      if (translated != null && translated.isNotEmpty) {
        return translated;
      }
    }
    return country.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding:
              const EdgeInsets.only(left: 15, right: 35, top: 20, bottom: 10),
          height: 70,
          child: TextFormField(
            key: Key(TestHelper.CountrySearchInputKeyValue),
            decoration: getSearchBoxDecoration(),
            controller: _searchController,
            autofocus: widget.autoFocus,
            onChanged: (value) =>
                setState(() => filteredCountries = filterCountries()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            shrinkWrap: true,
            itemCount: filteredCountries.length,
            itemBuilder: (BuildContext context, int index) {
              Country country = filteredCountries[index];
              if (country == null) return null;
              return ListTile(
                key: Key(TestHelper.countryItemKeyValue(country.alpha2Code)),
                leading: widget.showFlags
                    ? _Flag(
                        country: country,
                        shape: widget.shape,
                        useEmoji: widget.useEmoji)
                    : null,
                title: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${getCountryName(country)}',
                        textAlign: TextAlign.start)),
                subtitle: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${country?.dialCode ?? ''}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start)),
                onTap: () => Navigator.of(context).pop(country),
              );
            },
          ),
        ),
      ],
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
    return country != null
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

