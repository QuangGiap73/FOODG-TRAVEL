import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import '../../controller/l10n/locale_controller.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}
class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late String _selected; // luu ngon ngu dc chon
    @override
    void initState() {
        super.initState();
        final code = LocaleController().locale?.languageCode ?? 'vi';
        _selected = code;
    }
    // hàm chuyển đôi khi user chọn
    void _setLang(String code) {
        setState(() => _selected = code);
        LocaleController().setLocale(Locale(code));
    }
    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return Scaffold(
            appBar: AppBar(
                title: Text(t.language),
            ),
            body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                    Text(
                        t.chooseLanguage,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    RadioListTile<String>(
                        value: 'vi',
                        groupValue: _selected,
                        onChanged: (v) => _setLang(v!),
                        title: Text(t.vietnamese),
                    ),
                    RadioListTile<String>(
                        value: 'en',
                        groupValue: _selected,
                        onChanged: (v) => _setLang(v!),
                        title: Text(t.english),
                    ),
                
                ],
            ),
        );
    }
}
