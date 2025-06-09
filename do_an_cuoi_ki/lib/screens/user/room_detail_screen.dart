// lib/screens/user/room_detail_screen.dart

import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:do_an_cuoi_ki/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Sử dụng thư viện flutter_carousel_widget
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
// SỬA IMPORT: Đảm bảo import đúng RequestModel và hàm checkIfUserIsCurrentlyRenting
import 'package:do_an_cuoi_ki/models/request.dart';

// Helper extension đã có ở RoomListScreen, nếu chưa có ở file chung thì thêm vào đây
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Helper extension để format tên RequestType (tùy chọn, bạn có thể đặt ở file chung)
// Nếu đã có ở request_model.dart thì không cần khai báo lại
// extension StringFormattingExtension on String {
//   String capitalizeFirstLetterPerWord() {
//     if (isEmpty) return this;
//     return split(' ').map((word) {
//       if (word.isEmpty) return '';
//       if (word.length == 1) return word.toUpperCase();
//       return word[0].toUpperCase() + word.substring(1).toLowerCase();
//     }).join(' ');
//   }
// }


class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;
  final String userId;
  final String userSdt;
  final String userName;

  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.userId,
    required this.userSdt,
    required this.userName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final RequestService _requestService = RequestService();
  final RoomService _roomService = RoomService();

  // Hàm hiển thị dialog tạo yêu cầu đã được cập nhật
  void _showCreateRequestDialog(BuildContext context, String selectedRoomId) async { // Thêm async
    final formKey = GlobalKey<FormState>();

    // Gọi hàm kiểm tra từ request_model.dart
    // userId được lấy từ widget.userId (người dùng đang xem chi tiết)
     bool isCurrentlyRenting = await _requestService.checkIfUserIsCurrentlyRenting(widget.userId);

    List<RequestType> availableRequestTypes;
    RequestType? defaultSelectedType;

    // Logic kiểm tra xem phòng hiện tại có phải là phòng người dùng đang thuê không
    // Điều này quan trọng nếu người dùng có thể xem chi tiết phòng họ đang thuê
    bool isViewingRentedRoomByCurrentUser = isCurrentlyRenting && widget.room.currentTenantId == widget.userId;


    if (isCurrentlyRenting) {
      if (isViewingRentedRoomByCurrentUser && widget.room.id == selectedRoomId) {
        // Đang xem chi tiết phòng MÌNH đang thuê
        availableRequestTypes = [
          RequestType.traPhong,
          RequestType.suaChua,
        ];
        defaultSelectedType = RequestType.suaChua;
      } else {
        // Đang thuê một phòng KHÁC, và xem chi tiết một phòng TRỐNG
        // Logic ở đây tùy thuộc vào việc bạn có cho phép người dùng thuê thêm phòng không
        // Giả sử KHÔNG cho thuê thêm nếu đã thuê 1 phòng
        availableRequestTypes = [
          // RequestType.thuePhong, // Bỏ comment nếu cho thuê nhiều phòng
        ];
         // Nếu không có type nào, có thể không hiển thị nút hoặc hiển thị thông báo
        if (availableRequestTypes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã thuê một phòng khác. Không thể tạo yêu cầu cho phòng này.'))
          );
          return; // Không hiển thị dialog
        }
        defaultSelectedType = availableRequestTypes.isNotEmpty ? availableRequestTypes.first : null;
      }
    } else {
      // Nếu chưa thuê phòng, chỉ có thể yêu cầu thuê phòng (cho phòng hiện tại đang xem)
      availableRequestTypes = [RequestType.thuePhong];
      defaultSelectedType = RequestType.thuePhong;
    }

    // Nếu defaultSelectedType là null (do availableRequestTypes rỗng), không hiển thị dialog
    if (defaultSelectedType == null) {
       print("Không có loại yêu cầu nào phù hợp để hiển thị dialog.");
       return;
    }


    RequestType selectedType = defaultSelectedType;
    final TextEditingController moTaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Tạo yêu cầu mới'),
              contentPadding: const EdgeInsets.all(16.0),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RequestType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại yêu cầu',
                        border: OutlineInputBorder(),
                      ),
                      items: availableRequestTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.getDisplayName()), // Sử dụng getDisplayName
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedType = value;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn loại yêu cầu' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: moTaController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả yêu cầu',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Vui lòng nhập mô tả' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final request = RequestModel(
                        id: FirebaseFirestore.instance.collection('requests').doc().id,
                        loaiRequest: selectedType,
                        moTa: moTaController.text.trim(),
                        roomId: selectedRoomId,
                        userKhachId: widget.userId,
                        thoiGian: DateTime.now(),
                        sdt: widget.userSdt, 
                        Name: widget.userName,
                      );

                      try {
                        await _requestService.createRequest(request);

                        Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gửi yêu cầu thành công')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi gửi yêu cầu: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Gửi yêu cầu'),
                ),
              ],
            );
          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    // Xác định xem nút "Gửi yêu cầu" có nên hiển thị và hoạt động không
    // Dựa trên việc người dùng đã thuê phòng này, hoặc phòng này còn trống và người dùng chưa thuê phòng nào khác
    bool canMakeRequestForThisRoom = false;
    if (room.status == RoomStatus.available && !checkIfUserIsCurrentlyRentingSynchronous(widget.userId, room.id)) {
        // Phòng còn trống VÀ (người dùng chưa thuê phòng nào HOẶC người dùng đang xem phòng không phải phòng họ thuê)
        // Logic checkIfUserIsCurrentlyRentingSynchronous là giả định, bạn cần gọi hàm async và quản lý state
        // Tạm thời đơn giản hóa: nếu phòng available thì cho phép gửi yêu cầu thuê
        canMakeRequestForThisRoom = true;
    } else if (room.currentTenantId == widget.userId) {
        // Người dùng đang xem chi tiết phòng HỌ đang thuê
        canMakeRequestForThisRoom = true;
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(room.title.isNotEmpty ? room.title : "Chi tiết phòng"),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.imageUrls.isNotEmpty)
              _buildImageCarousel(room.imageUrls)
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey[500]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.attach_money,
                    "${room.price.toStringAsFixed(0)} VNĐ / tháng",
                    color: Colors.green.shade700,
                    isBold: true,
                  ),
                  _buildInfoRow(Icons.square_foot_outlined, "${room.area.toStringAsFixed(1)} m²"),
                  _buildInfoRow(Icons.people_alt_outlined, "Sức chứa: ${room.capacity} người"),
                  _buildInfoRow(Icons.location_pin, room.address.isNotEmpty ? room.address : "Chưa cập nhật địa chỉ"),
                  _buildInfoRow(
                    room.status == RoomStatus.available ? Icons.check_circle_outline : Icons.info_outline,
                    // Sử dụng capitalizeFirstLetter() đã định nghĩa ở đầu file
                    "Trạng thái: ${room.status.toJson().capitalizeFirstLetter()}",
                    color: room.status == RoomStatus.available ? Colors.green.shade600 : Colors.orange.shade700,
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildSectionTitle(context, "Mô tả chi tiết"),
                  Text(
                    room.description.isNotEmpty ? room.description : "Chủ nhà chưa cung cấp mô tả cho phòng này.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: Colors.grey.shade700),
                  ),
                  const Divider(height: 32, thickness: 1),
                  if (room.amenities.isNotEmpty) ...[
                    _buildSectionTitle(context, "Tiện nghi"),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: room.amenities.map((amenity) => Chip(
                        avatar: Icon(Icons.check, size: 16, color: Colors.green.shade700),
                        label: Text(amenity),
                        backgroundColor: Colors.green.shade50,
                      )).toList(),
                    ),
                    const Divider(height: 32, thickness: 1),
                  ],
                  if (room.sodien > 0) ...[
                     _buildSectionTitle(context, "Thông tin điện"),
                    _buildInfoRow(Icons.electrical_services_outlined, "Số điện tháng trước: ${room.sodien.toStringAsFixed(0)} kWh"),
                    const Divider(height: 32, thickness: 1),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      // Cập nhật logic hiển thị BottomNavigationBar
      bottomNavigationBar: _buildBottomBar(context, room, canMakeRequestForThisRoom),
    );
  }

  // Hàm giả định, bạn cần hàm async thực sự để kiểm tra
  bool checkIfUserIsCurrentlyRentingSynchronous(String userId, String currentRoomId) {
    // Đây chỉ là placeholder, bạn cần lấy trạng thái thuê phòng thực sự
    // Ví dụ: có thể truyền trạng thái này từ màn hình trước, hoặc quản lý bằng Provider/Bloc
    // Trong trường hợp này, _showCreateRequestDialog sẽ gọi hàm async.
    // Để đơn giản cho việc build bottom bar, ta có thể làm nó phức tạp hơn một chút
    // bằng cách dùng FutureBuilder cho bottom bar, hoặc truyền trạng thái isRenting.
    // Tạm thời, logic trong _showCreateRequestDialog sẽ là chính.
    return widget.room.currentTenantId == userId && widget.room.id != currentRoomId; // ví dụ đơn giản
  }


  Widget _buildBottomBar(BuildContext context, RoomModel room, bool canMakeRequest) {
    String buttonText = "Gửi yêu cầu";
    VoidCallback? onPressedAction = () {
        _showCreateRequestDialog(context, room.id);
    };

    // Điều chỉnh text và action dựa trên trạng thái phức tạp hơn
    if (room.currentTenantId == widget.userId && room.id == widget.room.id) {
        // Đang xem phòng mình thuê
        buttonText = "Tạo yêu cầu (Trả/Sửa)";
    } else if (room.status == RoomStatus.available) {
        buttonText = "Gửi yêu cầu thuê";
    } else if (room.status == RoomStatus.rented && room.currentTenantId != widget.userId) {
        // Phòng đã được người khác thuê
        buttonText = "Phòng đã được thuê";
        onPressedAction = null;
    } else if (room.status == RoomStatus.unavailable) {
        buttonText = "Phòng không khả dụng";
        onPressedAction = null;
    }
    // Thêm trường hợp người dùng đã thuê phòng khác
    // bool userIsRentingAnotherRoom = await checkIfUserIsCurrentlyRenting(widget.userId) && room.currentTenantId != widget.userId;
    // Để kiểm tra điều này một cách chính xác cho bottom bar, bạn cần gọi hàm async,
    // điều này làm phức tạp việc build bottom bar trực tiếp.
    // Cách tốt nhất là _showCreateRequestDialog sẽ xử lý việc có hiển thị dialog hay không.
    // Nút bottom bar có thể luôn là "Gửi yêu cầu" nếu phòng available,
    // và dialog sẽ thông báo nếu không hợp lệ.

    // Đơn giản hóa logic cho nút bottom bar:
    if (room.status == RoomStatus.available) {
        buttonText = "Liên hệ chủ trọ"; // Hoặc "Gửi yêu cầu thuê"
        onPressedAction = () => _showCreateRequestDialog(context, room.id);
    } else if (room.currentTenantId == widget.userId) {
        // Người dùng đang xem phòng họ thuê
        buttonText = "Yêu cầu (Trả/Sửa)";
        onPressedAction = () => _showCreateRequestDialog(context, room.id);
    } else {
        // Phòng đã thuê bởi người khác hoặc không khả dụng
        buttonText = "Phòng đã ${room.status.toJson().capitalizeFirstLetter()}";
        onPressedAction = null;
    }


    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.contact_mail_outlined),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressedAction != null ? Colors.amber.shade700 : Colors.grey.shade400,
          foregroundColor: onPressedAction != null ? Colors.black : Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressedAction,
      ),
    );
  }


  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCustomDotIndicator(int itemCount, int currentIndex) {
    if (itemCount <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Colors.green.shade800 // Màu của dot được chọn
                : Colors.grey.shade400,  // Màu của dot không được chọn
          ),
        );
      }),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    return Column(
      children: [
        FlutterCarousel(
          options: CarouselOptions(
            height: 280.0,
            autoPlay: imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            aspectRatio: 16 / 9,
            showIndicator: false, // TẮT INDICATOR MẶC ĐỊNH
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: imageUrls.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        // Sử dụng indicator tùy chỉnh
        _buildCustomDotIndicator(imageUrls.length, _currentImageIndex),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: color ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}