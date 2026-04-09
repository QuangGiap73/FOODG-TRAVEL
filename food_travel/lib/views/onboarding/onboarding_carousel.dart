import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/route_names.dart';
import '../../controller/l10n/locale_controller.dart';

/// Onboarding carousel mô phỏng layout HTML: 3 slide + sheet xin quyền vị trí.
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _page = PageController();
  int _index = 0;

  final _slides = const [
    _Slide(
      title: 'Tìm quán ngon theo vị bạn thích',
      desc:
          'Bún bò, cơm tấm, lẩu, cà phê… chỉ vài chạm để tìm thấy hương vị chuẩn gu.',
      img:
          'https://images.unsplash.com/photo-1582878826618-c05326eff950?q=80&w=800&auto=format&fit=crop',
    ),
    _Slide(
      title: 'Gần bạn, mở cửa, giá hợp lý',
      desc:
          'Xem khoảng cách thực tế, giờ mở cửa và mức giá trung bình trước khi đến.',
      img:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800&auto=format&fit=crop',
    ),
    _Slide(
      title: 'Lưu list & chia sẻ cùng bạn bè',
      desc:
          'Tạo danh sách “Muốn thử” và rủ rê hội bạn thân cùng đi ăn sập quán.',
      img:
          'https://images.unsplash.com/photo-1563245372-f21724e3856d?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  Future<void> _showPermissionSheet() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LocationPermissionSheet(),
    );
    if (ok == true && mounted) {
      await _completeOnboarding();
    }
  }

  Future<void> _showLanguageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LanguageSheet(),
    );
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _showLanguageSheet().then((_) => _showPermissionSheet());
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      body: PageView.builder(
        controller: _page,
        itemCount: _slides.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => _SlideView(
          slide: _slides[i],
          index: i,
          total: _slides.length,
          onSkip: _completeOnboarding,
          onNext: _next,
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  final _Slide slide;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero image + skip
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  slide.img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 52,
                right: 16,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black26,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Bỏ qua'),
                ),
              ),
            ],
          ),
        ),
        // Card
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Color(0x1F000000),
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(total, (dot) {
                    final active = dot == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      height: 6,
                      width: active ? 22 : 8,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFF6A00)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Text(
                  slide.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.orange.shade200,
                      elevation: 8,
                    ),
                    child: Text(
                      index == total - 1 ? 'Bắt đầu ngay' : 'Tiếp tục',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide {
  final String title, desc, img;
  const _Slide({required this.title, required this.desc, required this.img});
}

class _LocationPermissionSheet extends StatelessWidget {
  const _LocationPermissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(Icons.location_on_outlined,
                color: Color(0xFFFF6A00), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Cho phép vị trí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Để gợi ý quán ngon gần bạn nhất, chúng tôi cần quyền truy cập vị trí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Column(
              children: const [
                _Point(icon: Icons.radar, text: 'Gợi ý chính xác khu vực'),
                SizedBox(height: 10),
                _Point(icon: Icons.alt_route, text: 'Chỉ đường nhanh chóng'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final perm = await Geolocator.requestPermission();
                  final ok = perm == LocationPermission.always ||
                      perm == LocationPermission.whileInUse;
                  // gộp cả grant + decline vào pop, caller sẽ xử lý
                  Navigator.pop(context, ok);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Cho phép vị trí'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Để sau',
                style: TextStyle(color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6A00)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet();

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _code = LocaleController().locale?.languageCode ?? 'vi';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn ngôn ngữ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _Option(
              label: 'Tiếng Việt',
              value: 'vi',
              group: _code,
              onChanged: (v) => setState(() => _code = v),
            ),
            _Option(
              label: 'English',
              value: 'en',
              group: _code,
              onChanged: (v) => setState(() => _code = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final target = _code;
                  await LocaleController().setLocale(
                    target.isEmpty ? null : Locale(target),
                  );
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  });
  final String label;
  final String value;
  final String group;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: group,
              activeColor: const Color(0xFFFF6A00),
              onChanged: (v) => onChanged(v!),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
