import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pokemon_market/widgets/common_appbar.dart';
import 'package:pokemon_market/widgets/common_text.dart';
import 'package:pokemon_market/theme/custom_theme.dart';
import 'package:pokemon_market/theme/theme_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ProductAddPage extends StatefulWidget {
  const ProductAddPage({super.key});

  @override
  State<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_formatPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.removeListener(_formatPrice);
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _formatPrice() {
    String text = _priceController.text.replaceAll(',', '');
    if (text.isNotEmpty) {
      final number = int.tryParse(text);
      if (number != null) {
        final formatter = NumberFormat('#,###');
        String formatted = formatter.format(number);
        if (formatted != _priceController.text) {
          _priceController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    }
  }

  Future<String?> _saveImageToLocal(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String newPath =
          '${directory.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File newImage = await image.copy(newPath);
      return newImage.path;
    } catch (e) {
      print('이미지 저장 실패: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  ThemeColors _getThemeColors(bool isDark) {
    return ThemeColors(
      containerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      textColor: isDark ? Colors.white : Colors.black,
      hintColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      imageAreaColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      imageIconColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
    );
  }

  Widget _buildImageSelector(ThemeColors colors) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: colors.imageAreaColor,
          borderRadius: BorderRadius.circular(12),
          image: _image != null
              ? DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _image == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: colors.imageIconColor,
                    ),
                    const SizedBox(height: 10),
                    CommonText(
                      text: 'image선택',
                      fontSize: 18,
                      textColor: colors.imageIconColor,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required ThemeColors colors,
    TextInputType? keyboardType,
    String? hintText,
    bool isExpanded = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final textField = TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: colors.textColor),
      maxLines: isExpanded ? null : 1,
      expands: isExpanded,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: TextStyle(color: colors.hintColor),
      ),
    );

    if (isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(text: label, fontSize: 18),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: textField,
          ),
        ],
      );
    }

    return Row(
      children: [
        CommonText(text: label, fontSize: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: textField,
          ),
        ),
        if (label == '상품가격') ...[
          const SizedBox(width: 10),
          CommonText(text: '원', fontSize: 18),
        ],
      ],
    );
  }

  Widget _buildQuantitySelector(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            if (_quantity > 1) {
              setState(() {
                _quantity--;
              });
            }
          },
          icon: const Icon(Icons.remove),
          color: colors.textColor,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: colors.containerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CommonText(
            text: '$_quantity',
            fontSize: 18,
            textColor: colors.textColor,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _quantity++;
            });
          },
          icon: const Icon(Icons.add),
          color: colors.textColor,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    return ElevatedButton(
      onPressed: () async {
        String? imagePath;
        if (_image != null) {
          imagePath = await _saveImageToLocal(_image!);
        }
        final product = {
          'name': _nameController.text,
          'price': _priceController.text,
          'description': _descriptionController.text,
          'quantity': _quantity,
          'imagePath': imagePath,
        };
        Navigator.pop(context, product);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? const Color.fromARGB(255, 0, 120, 215) // 다크모드: 포켓몬 파란색
            : const Color.fromARGB(255, 255, 203, 5), // 라이트모드: 포켓몬 노란색
        foregroundColor: isDark
            ? Colors.white // 다크모드: 흰색 텍스트
            : Colors.black, // 라이트모드: 검은색 텍스트
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const CommonText(
        text: '등록하기',
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final colors = _getThemeColors(themeManager.isDarkMode);

    return Theme(
      data: themeManager.isDarkMode ? darkTheme : lightTheme,
      child: Scaffold(
        appBar: CommonAppbar(
          isDarkMode: themeManager.isDarkMode,
          toggleTheme: themeManager.toggleTheme,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildImageSelector(colors),
                  const SizedBox(height: 30),
                  _buildInputField(
                    label: '상품이름',
                    controller: _nameController,
                    colors: colors,
                    hintText: '상품 이름을 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: '상품가격',
                    controller: _priceController,
                    colors: colors,
                    keyboardType: TextInputType.number,
                    hintText: '가격을 입력하세요',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: '상품설명',
                    controller: _descriptionController,
                    colors: colors,
                    hintText: '상품 설명을 입력하세요',
                    isExpanded: true,
                  ),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeColors {
  final Color containerColor;
  final Color textColor;
  final Color hintColor;
  final Color imageAreaColor;
  final Color imageIconColor;

  const ThemeColors({
    required this.containerColor,
    required this.textColor,
    required this.hintColor,
    required this.imageAreaColor,
    required this.imageIconColor,
  });
}
