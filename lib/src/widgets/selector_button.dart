import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/utils/selector_config.dart';
import 'package:intl_phone_number_input/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input/src/widgets/countries_search_list_widget.dart';
import 'package:intl_phone_number_input/src/widgets/input_widget.dart';
import 'package:intl_phone_number_input/src/widgets/item.dart';

class SelectorButton extends StatelessWidget {
  final List<Country> countries;
  final Country country;
  final SelectorConfig selectorConfig;
  final TextStyle selectorTextStyle;
  final InputDecoration searchBoxDecoration;
  final bool autoFocusSearchField;
  final String locale;
  final bool isEnabled;
  final bool showCode;
  final bool isScrollControlled;
  final BoxShape shape;

  final ValueChanged<Country> onCountryChanged;

  const SelectorButton({
    Key key,
    @required this.countries,
    @required this.country,
    @required this.selectorConfig,
    @required this.selectorTextStyle,
    @required this.searchBoxDecoration,
    @required this.autoFocusSearchField,
    @required this.locale,
    @required this.onCountryChanged,
    @required this.isEnabled,
    @required this.showCode,
    @required this.isScrollControlled,
    @required this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return selectorConfig.selectorType == PhoneInputSelectorType.DROPDOWN
        ? countries.isNotEmpty && countries.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<Country>(
                  key: Key(TestHelper.DropdownButtonKeyValue),
                  hint: Item(
                      country: country,
                      showFlag: selectorConfig.showFlags,
                      useEmoji: selectorConfig.useEmoji,
                      textStyle: selectorTextStyle,
                      showCode: showCode,
                      shape: shape),
                  value: country,
                  items: mapCountryToDropdownItem(countries),
                  onChanged: isEnabled ? onCountryChanged : null,
                ),
              )
            : Item(
                country: country,
                showFlag: selectorConfig.showFlags,
                useEmoji: selectorConfig.useEmoji,
                textStyle: selectorTextStyle,
                showCode: showCode,
                shape: shape)
        : MaterialButton(
            key: Key(TestHelper.DropdownButtonKeyValue),
            padding: EdgeInsets.zero,
            minWidth: 0,
            onPressed: countries.isNotEmpty && countries.length > 1
                ? () async {
                    Country selected;
                    if (selectorConfig.selectorType ==
                        PhoneInputSelectorType.BOTTOM_SHEET) {
                      selected = await showCountrySelectorBottomSheet(
                          context, countries);
                    } else {
                      selected =
                          await showCountrySelectorDialog(context, countries);
                    }

                    if (selected != null) {
                      onCountryChanged(selected);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Item(
                  country: country,
                  showFlag: selectorConfig.showFlags,
                  useEmoji: selectorConfig.useEmoji,
                  textStyle: selectorTextStyle,
                  showCode: showCode,
                  shape: shape),
            ),
          );
  }

  List<DropdownMenuItem<Country>> mapCountryToDropdownItem(
      List<Country> countries) {
    return countries.map((country) {
      return DropdownMenuItem<Country>(
        value: country,
        child: Item(
          key: Key(TestHelper.countryItemKeyValue(country.alpha2Code)),
          country: country,
          showFlag: selectorConfig.showFlags,
          useEmoji: selectorConfig.useEmoji,
          textStyle: selectorTextStyle,
          shape: shape,
          withCountryNames: false,
        ),
      );
    }).toList();
  }

  Future<Country> showCountrySelectorDialog(
      BuildContext context, List<Country> countries) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        content: Container(
          width: double.maxFinite,
          child: CountrySearchListWidget(countries, locale,
              searchBoxDecoration: searchBoxDecoration,
              showFlags: selectorConfig.showFlags,
              useEmoji: selectorConfig.useEmoji,
              autoFocus: autoFocusSearchField,
              shape: shape),
        ),
      ),
    );
  }

  Future<Country> showCountrySelectorBottomSheet(
      BuildContext context, List<Country> countries) {
    return showModalBottomSheet(
      context: context,
      clipBehavior: Clip.hardEdge,
      isScrollControlled: isScrollControlled ?? true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      builder: (BuildContext context) {
        return AnimatedPadding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          duration: const Duration(milliseconds: 100),
          child: DraggableScrollableSheet(
            builder: (BuildContext context, ScrollController controller) {
              return Container(
                decoration: ShapeDecoration(
                  color: selectorConfig.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: CountrySearchListWidget(countries, locale,
                    searchBoxDecoration: searchBoxDecoration,
                    scrollController: controller,
                    showFlags: selectorConfig.showFlags,
                    useEmoji: selectorConfig.useEmoji,
                    autoFocus: autoFocusSearchField,
                    shape: shape),
              );
            },
          ),
        );
      },
    );
  }
}

