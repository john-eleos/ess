import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/src/models/country_list.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/providers/country_provider.dart';
import 'package:intl_phone_number_input/src/utils/formatter/as_you_type_formatter.dart';
import 'package:intl_phone_number_input/src/utils/phone_number.dart';
import 'package:intl_phone_number_input/src/utils/selector_config.dart';
import 'package:intl_phone_number_input/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input/src/utils/util.dart';
import 'package:intl_phone_number_input/src/utils/widget_view.dart';
import 'package:intl_phone_number_input/src/widgets/selector_button.dart';
import 'package:libphonenumber/libphonenumber.dart';

/// Enum for [SelectorButton] types.
///
/// Available type includes:
///   * [PhoneInputSelectorType.DROPDOWN]
///   * [PhoneInputSelectorType.BOTTOM_SHEET]
///   * [PhoneInputSelectorType.DIALOG]
enum PhoneInputSelectorType { DROPDOWN, BOTTOM_SHEET, DIALOG }

/// A [TextFormField] for [InternationalPhoneNumberInput].
///
/// [initialValue] accepts a [PhoneNumber] this is used to set initial values
/// for phone the input field and the selector button
///
/// [selectorButtonOnErrorPadding] is a double which is used to align the selector
/// button with the input field when an error occurs
///
/// [locale] accepts a country locale which will be used to translation, if the
/// translation exist
///
/// [countries] accepts list of string on Country isoCode, if specified filters
/// available countries to match the [countries] specified.
class InternationalPhoneNumberInput extends StatefulWidget {
  final SelectorConfig selectorConfig;

  final ValueChanged<PhoneNumber> onInputChanged;
  final ValueChanged<bool> onInputValidated;

  final VoidCallback onSubmit;
  final ValueChanged<String> onFieldSubmitted;
  final String Function(String) validator;
  final Function(String) onSaved;

  final TextEditingController textFieldController;
  final TextInputAction keyboardAction;

  final PhoneNumber initialValue;
  final String hintText;
  final String errorMessage;

  final double selectorButtonOnErrorPadding;
  final int maxLength;

  final bool isEnabled;
  final bool showCode;
  final bool formatInput;
  final bool autoFocus;
  final bool autoFocusSearch;
  final AutovalidateMode autoValidateMode;
  final bool ignoreBlank;
  final bool countrySelectorScrollControlled;

  final String locale;

  final TextStyle textStyle;
  final TextStyle selectorTextStyle;
  final InputBorder inputBorder;
  final InputDecoration inputDecoration;
  final InputDecoration searchBoxDecoration;

  final FocusNode focusNode;

  final List<String> countries;
  final BoxShape shape;

  InternationalPhoneNumberInput(
      {Key key,
      this.selectorConfig = const SelectorConfig(),
      @required this.onInputChanged,
      this.onInputValidated,
      this.onSubmit,
      this.onFieldSubmitted,
      this.validator,
      this.onSaved,
      this.textFieldController,
      this.keyboardAction,
      this.initialValue,
      this.hintText = 'Phone number',
      this.errorMessage = 'Invalid phone number',
      this.selectorButtonOnErrorPadding = 24,
      this.maxLength = 15,
      this.isEnabled = true,
      this.showCode = false,
      this.formatInput = true,
      this.autoFocus = false,
      this.autoFocusSearch = false,
      this.autoValidateMode = AutovalidateMode.disabled,
      this.ignoreBlank = false,
      this.countrySelectorScrollControlled = true,
      this.locale,
      this.textStyle,
      this.selectorTextStyle,
      this.inputBorder,
      this.inputDecoration,
      this.searchBoxDecoration,
      this.focusNode,
      this.shape,
      this.countries})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InternationalPhoneNumberInput> {
  TextEditingController controller;
  double selectorButtonBottomPadding = 0;

  Country country;
  List<Country> countries = [];
  bool isNotValid = true;

  @override
  void initState() {
    Future.delayed(Duration.zero, () => loadCountries());
    controller = widget.textFieldController ?? TextEditingController();
    initialiseWidget();
    super.initState();
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InputWidgetView(
      state: this,
    );
  }

  @override
  void didUpdateWidget(InternationalPhoneNumberInput oldWidget) {
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.initialValue?.hash != widget.initialValue?.hash) {
      loadCountries();
      initialiseWidget();
    }
    super.didUpdateWidget(oldWidget);
  }

  /// [initialiseWidget] sets initial values of the widget
  void initialiseWidget() async {
    if (widget.initialValue != null) {
      if (widget.initialValue.phoneNumber != null &&
          widget.initialValue.phoneNumber.isNotEmpty &&
          await PhoneNumberUtil.isValidPhoneNumber(
              phoneNumber: widget.initialValue.phoneNumber,
              isoCode: widget.initialValue.isoCode)) {
        controller.text =
            await PhoneNumber.getParsableNumber(widget.initialValue);

        phoneNumberControllerListener();
      }
    }
  }

  /// loads countries from [Countries.countryList] and selected Country
  void loadCountries() {
    if (this.mounted) {
      List<Country> countries =
          CountryProvider.getCountriesData(countries: widget.countries);

      final CountryComparator countryComparator =
          widget.selectorConfig?.countryComparator;
      if (countryComparator != null) {
        countries.sort(countryComparator);
      }

      Country country = Utils.getInitialSelectedCountry(
        countries,
        widget.initialValue?.isoCode ?? '',
      );

      setState(() {
        this.countries = countries;
        this.country = country;
      });
    }
  }

  /// Listener that validates changes from the widget, returns a bool to
  /// the `ValueCallback` [widget.onInputValidated]
  void phoneNumberControllerListener() {
    if (this.mounted) {
      String parsedPhoneNumberString =
          controller.text.replaceAll(RegExp(r'[^\d+]'), '');

      getParsedPhoneNumber(parsedPhoneNumberString, this.country?.alpha2Code)
          .then((phoneNumber) {
        if (phoneNumber == null) {
          String phoneNumber =
              '${this.country?.dialCode}$parsedPhoneNumberString';

          if (widget.onInputChanged != null) {
            widget.onInputChanged(PhoneNumber(
                phoneNumber: phoneNumber,
                isoCode: this.country?.alpha2Code,
                dialCode: this.country?.dialCode));
          }

          if (widget.onInputValidated != null) {
            widget.onInputValidated(false);
          }
          this.isNotValid = true;
        } else {
          if (widget.onInputChanged != null) {
            widget.onInputChanged(PhoneNumber(
                phoneNumber: phoneNumber,
                isoCode: this.country?.alpha2Code,
                dialCode: this.country?.dialCode));
          }

          if (widget.onInputValidated != null) {
            widget.onInputValidated(true);
          }
          this.isNotValid = false;
        }
      });
    }
  }

  /// Returns a formatted String of [phoneNumber] with [isoCode], returns `null`
  /// if [phoneNumber] is not valid or if an [Exception] is caught.
  Future<String> getParsedPhoneNumber(
      String phoneNumber, String isoCode) async {
    if (phoneNumber.isNotEmpty && isoCode != null) {
      try {
        bool isValidPhoneNumber = await PhoneNumberUtil.isValidPhoneNumber(
            phoneNumber: phoneNumber, isoCode: isoCode);

        if (isValidPhoneNumber) {
          return await PhoneNumberUtil.normalizePhoneNumber(
              phoneNumber: phoneNumber, isoCode: isoCode);
        }
      } on Exception {
        return null;
      }
    }
    return null;
  }

  /// Creates or Select [InputDecoration]
  InputDecoration getInputDecoration(
      {InputDecoration decoration, Widget prefix}) {
    return decoration != null
        ? InputDecoration(
            alignLabelWithHint: decoration?.alignLabelWithHint,
            border: decoration?.border,
            contentPadding: decoration?.contentPadding,
            counter: decoration?.counter,
            counterStyle: decoration?.counterStyle,
            counterText: decoration?.counterText,
            disabledBorder: decoration?.disabledBorder,
            enabled: decoration?.enabled,
            enabledBorder: decoration?.enabledBorder,
            errorBorder: decoration?.errorBorder,
            errorMaxLines: decoration?.errorMaxLines,
            errorStyle: decoration?.errorStyle,
            errorText: decoration?.errorText,
            fillColor: decoration?.fillColor,
            filled: decoration?.filled,
            floatingLabelBehavior: decoration?.floatingLabelBehavior,
            focusColor: decoration?.focusColor,
            focusedBorder: decoration?.focusedBorder,
            focusedErrorBorder: decoration?.focusedErrorBorder,
            helperMaxLines: decoration?.helperMaxLines,
            helperStyle: decoration?.helperStyle,
            helperText: decoration?.helperText,
            hintMaxLines: decoration?.hintMaxLines,
            hintStyle: decoration?.hintStyle,
            hintText: decoration?.hintText,
            hoverColor: decoration?.hoverColor,
            icon: decoration?.icon,
            isCollapsed: decoration?.isCollapsed,
            isDense: decoration?.isDense,
            labelStyle: decoration?.labelStyle,
            labelText: decoration?.labelText,
            semanticCounterText: decoration?.semanticCounterText,
            suffix: decoration?.suffix,
            suffixIcon: decoration?.suffixIcon,
            suffixIconConstraints: decoration?.suffixIconConstraints,
            suffixStyle: decoration?.suffixStyle,
            suffixText: decoration?.suffixText,
            prefixIcon: Container(
              padding: EdgeInsets.only(left: 20),
              width: 100,
              child: prefix,
            ),
            prefix: decoration?.prefix,
            prefixIconConstraints: decoration?.prefixIconConstraints,
            prefixStyle: decoration?.prefixStyle,
            prefixText: decoration?.prefixText,
          )
        : InputDecoration(
            border: widget.inputBorder ?? UnderlineInputBorder(),
            hintText: widget.hintText,
            prefixIcon: Container(
              padding: EdgeInsets.only(left: 20),
              width: 100,
              child: prefix,
            ),
          );
  }

  /// Validate the phone number when a change occurs
  void onChanged(String value) {
    TextSelection previousSelection = controller.selection;
    controller.text = value;
    controller.selection = previousSelection;
    phoneNumberControllerListener();
  }

  /// Validate and returns a validation error when [FormState] validate is called.
  ///
  /// Also updates [selectorButtonBottomPadding]
  String validator(String value) {
    bool isValid =
        this.isNotValid && (value.isNotEmpty || widget.ignoreBlank == false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isValid && widget.errorMessage != null) {
        setState(() {
          this.selectorButtonBottomPadding =
              widget.selectorButtonOnErrorPadding ?? 24;
        });
      } else {
        setState(() {
          this.selectorButtonBottomPadding = 0;
        });
      }
    });

    return isValid ? widget.errorMessage : null;
  }

  /// Changes Selector Button Country and Validate Change.
  void onCountryChanged(Country country) {
    setState(() {
      this.country = country;
    });
    phoneNumberControllerListener();
  }
}

class _InputWidgetView
    extends WidgetView<InternationalPhoneNumberInput, _InputWidgetState> {
  final _InputWidgetState state;

  _InputWidgetView({Key key, @required this.state})
      : super(key: key, state: state);

  @override
  Widget build(BuildContext context) {
    final countryCode = state?.country?.alpha2Code ?? '';
    final dialCode = state?.country?.dialCode ?? '';

    return TextFormField(
      key: Key(TestHelper.TextInputKeyValue),
      textDirection: TextDirection.ltr,
      controller: state.controller,
      focusNode: widget.focusNode,
      enabled: widget.isEnabled,
      autofocus: widget.autoFocus,
      keyboardType: TextInputType.phone,
      textInputAction: widget.keyboardAction,
      style: widget.textStyle,
      decoration: state.getInputDecoration(
        decoration: widget.inputDecoration,
        prefix: SelectorButton(
          shape: widget.shape,
          country: state.country,
          countries: state.countries,
          onCountryChanged: state.onCountryChanged,
          selectorConfig: widget.selectorConfig,
          selectorTextStyle: widget.selectorTextStyle,
          searchBoxDecoration: widget.searchBoxDecoration,
          locale: widget.locale,
          isEnabled: widget.isEnabled,
          showCode: widget.showCode,
          autoFocusSearchField: widget.autoFocusSearch,
          isScrollControlled: widget.countrySelectorScrollControlled,
        ),
      ),
      onEditingComplete: widget.onSubmit,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: widget.autoValidateMode,
      validator: widget.validator ?? state.validator,
      onSaved: widget.onSaved,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
        widget.formatInput
            ? AsYouTypeFormatter(
                isoCode: countryCode,
                dialCode: dialCode,
                onInputFormatted: (TextEditingValue value) {
                  state.controller.value = value;
                },
              )
            : FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: state.onChanged,
    );
  }
}
