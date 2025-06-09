import 'package:do_an_cuoi_ki/models/bill/bill.dart';
// File: screens/user/my_room_screen.dart
import 'package:do_an_cuoi_ki/services/contract_service.dart';
import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:do_an_cuoi_ki/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/request.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:do_an_cuoi_ki/services/bill_service.dart';
import 'package:intl/intl.dart';

class MyRoomScreen extends StatefulWidget {
  final UserModel? currentUser;

  const MyRoomScreen({super.key, required this.currentUser});

  @override
  State<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen> {
  ContractModel? _activeContract;
  RoomModel? _rentedRoom;
  bool _isLoading = true;
  String _loadingMessage = "Đang tải thông tin trọ của bạn...";
  List<PhieuSuaChua> _phieuSuaChuaList = [];
  List<RequestModel> _requestList = []; // Yêu cầu chờ xử lý
  List<RequestModel> _cancelledRequestList = []; // Yêu cầu đã hủy
  BillModel? _currentBill;

  // Biến trạng thái để kiểm soát việc mở rộng/thu gọn của từng phần
  bool _isRoomInfoExpanded = true;
  bool _isRecentActivitiesExpanded = true;
  bool _isPendingRequestsExpanded = true;
  bool _isCancelledRequestsExpanded = true;
  bool _isAllPhieuSuaExpanded = true;
  bool _isCurrentBillExpanded = true;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final RequestService _requestService = RequestService();
  final BillService _billService = BillService();
  final ContractService _contractService = ContractService();
  final RoomService _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      _fetchRentedRoomInfo();
    } else {
      setState(() {
        _isLoading = false;
        _loadingMessage = "Vui lòng đăng nhập để xem thông tin trọ.";
      });
    }
  }
  @override
  void didUpdateWidget(covariant MyRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      if (widget.currentUser != null) {
        _fetchRentedRoomInfo();
      } else {
        setState(() {
          _isLoading = false;
          _activeContract = null;
          _rentedRoom = null;
          _phieuSuaChuaList = [];
          _requestList = [];
          _cancelledRequestList = [];
          _currentBill = null;
          _loadingMessage = "Không có thông tin để hiển thị.";
        });
      }
    }
  }

  Future<void> _fetchRentedRoomInfo() async {
    if (widget.currentUser == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Đang tìm kiếm phòng bạn đang thuê...";
    });

    try {
      // Tìm hợp đồng hiện tại
      final contractsSnapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .where('tenantId', isEqualTo: widget.currentUser!.id)
          .where('status', isEqualTo: ContractStatus.active.toJson())
          .limit(1)
          .get();

      if (contractsSnapshot.docs.isNotEmpty) {
        final contractData = contractsSnapshot.docs.first.data();
        contractData['id'] = contractsSnapshot.docs.first.id;
        _activeContract = ContractModel.fromJson(contractData);

        // Tải phòng
        if (_activeContract?.roomId != null) {
          final roomSnapshot = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(_activeContract!.roomId)
              .get();

          if (roomSnapshot.exists) {
            Map<String, dynamic> roomData = Map.from(roomSnapshot.data()!);
            roomData['id'] = roomSnapshot.id;
            _rentedRoom = RoomModel.fromJson(roomData);

            // Tải danh sách yêu cầu sửa chữa CHỜ XỬ LÝ (status: 'pending')
            final pendingRequestSnapshot = await FirebaseFirestore.instance
                .collection('requests')
                // ĐÃ SẮP XẾP LẠI THỨ TỰ WHERE ĐỂ KHỚP VỚI INDEX (loai_request, room_id, status, user_khach_id, thoi_gian)
                .where('loai_request', isEqualTo: 'sua_chua') // Theo chỉ mục Firestore
                .where('room_id', isEqualTo: _rentedRoom!.id) // Theo chỉ mục Firestore
                .where('status', isEqualTo: 'pending')
                .where('user_khach_id', isEqualTo: widget.currentUser!.id) // Theo chỉ mục Firestore
                .orderBy('thoi_gian', descending: true) // Theo chỉ mục Firestore
                .get();
            _requestList = pendingRequestSnapshot.docs
                .map((doc) => RequestModel.fromJson({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();

            // Tải danh sách yêu cầu ĐÃ HỦY (status: 'cancelled')
            final cancelledRequestSnapshot = await FirebaseFirestore.instance
                .collection('requests')
                // ĐÃ SẮP XẾP LẠI THỨ TỰ WHERE ĐỂ KHỚP VỚI INDEX
                .where('loai_request', isEqualTo: 'sua_chua') // Theo chỉ mục Firestore
                .where('room_id', isEqualTo: _rentedRoom!.id) // Theo chỉ mục Firestore
                .where('status', isEqualTo: 'cancelled')
                .where('user_khach_id', isEqualTo: widget.currentUser!.id) // Theo chỉ mục Firestore
                .orderBy('thoi_gian', descending: true) // Theo chỉ mục Firestore
                .get();
            _cancelledRequestList = cancelledRequestSnapshot.docs
                .map((doc) => RequestModel.fromJson({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();

            // Tải danh sách phiếu sửa chữa (sử dụng 'roomId' như trong phieu_sua)
            final phieuSnapshot = await FirebaseFirestore.instance
                .collection('phieu_sua')
                .where('roomId', isEqualTo: _rentedRoom!.id)
                .get();
            _phieuSuaChuaList = phieuSnapshot.docs
                .map((doc) => PhieuSuaChua.fromFirestore(doc, null))
                .toList();

            // Tải hóa đơn tháng hiện tại
            final billSnapshot = await FirebaseFirestore.instance
                .collection('bills')
                .where('roomId', isEqualTo: _rentedRoom!.id) // Giữ nguyên 'roomId' nếu đó là tên trường trong collection 'bills'
                .where('thangNam', isEqualTo: DateFormat('MM/yyyy').format(DateTime.now()))
                .limit(1)
                .get();
            if (billSnapshot.docs.isNotEmpty) {
              _currentBill = BillModel.fromJson({
                ...billSnapshot.docs.first.data(),
                'id': billSnapshot.docs.first.id,
              });
            }
          } else {
            _loadingMessage = "Phòng không tồn tại trong hệ thống.";
            _rentedRoom = null;
          }
        } else {
          _loadingMessage = "Hợp đồng không chứa thông tin phòng.";
          _rentedRoom = null;

        }
      } else {
        _loadingMessage = "Bạn chưa thuê phòng nào.";
        _activeContract = null;
        _rentedRoom = null;
      }
    } catch (e) {
      print("Lỗi khi tải thông tin: $e");
      _loadingMessage = "Đã xảy ra lỗi khi tải dữ liệu.";
      _activeContract = null;
      _rentedRoom = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showCreateRequestDialog(RequestType initialType) {
    if (widget.currentUser == null || _rentedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra thông tin phòng hoặc đăng nhập lại.')),
      );
      return;
    }

    if (widget.currentUser!.id == null || widget.currentUser!.name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông tin người dùng không đầy đủ.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    RequestType selectedType = initialType;
    final TextEditingController moTaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Tạo yêu cầu ${initialType == RequestType.suaChua ? "Sửa chữa" : "Trả phòng"}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Phòng: ${_rentedRoom!.title}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: moTaController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    border: const OutlineInputBorder(),
                    hintText: initialType == RequestType.suaChua
                        ? "Ví dụ: Vòi nước rò rỉ..."
                        : "Ví dụ: Lý do trả phòng...",
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
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
                  // Đảm bảo request.toJson() tạo các trường theo tên đúng trong Firestore
                  // Dựa trên hình ảnh Firestore bạn gửi: room_id, loai_request, mo_ta, thoi_gian, user_khach_id
                  final request = RequestModel(
                    id: FirebaseFirestore.instance.collection('requests').doc().id,
                    loaiRequest: selectedType,
                    moTa: moTaController.text.trim(),
                    roomId: _rentedRoom!.id,
                    userKhachId: widget.currentUser!.id,
                    thoiGian: DateTime.now(),
                    sdt: widget.currentUser!.phoneNumber ?? 'N/A',
                    Name: widget.currentUser!.name,
                    status: 'pending',
                  );

                  try {
                    // Đây là nơi RequestModel.toJson() cần chuyển sang underscore_case
                    await FirebaseFirestore.instance
                        .collection('requests')
                        .doc(request.id)
                        .set(request.toJson());

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gửi yêu cầu thành công!')),
                    );
                    
                    Navigator.pop(dialogContext);

                    if (mounted) { 
                      await _fetchRentedRoomInfo();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi gửi yêu cầu: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhieuSuaChuaDetailDialog(PhieuSuaChua phieu) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Phiếu Sửa Chữa #${phieu.id!.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngày: ${DateFormat('dd/MM/yyyy').format(phieu.ngaySua)}'),
              Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi').format(phieu.tongTien)}'),
              Text('Trạng thái: ${phieu.statusText}'),
              Text('Nguồn lỗi: ${phieu.faultSourceText}'),
              if (phieu.requestId != null)
                Text('Yêu cầu: #${phieu.requestId!.substring(0, 8)}'),
              const SizedBox(height: 16),
              const Text('Hạng mục:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (phieu.items != null && phieu.items!.isNotEmpty)
                ...phieu.items!.map((item) => ListTile(
                      title: Text(item.info),
                      trailing: Text(NumberFormat.currency(locale: 'vi').format(item.cost)),
                    ))
              else
                const Text('Không có hạng mục.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(_loadingMessage),
            ],
          ),
        ),
      );
    }

    if (_rentedRoom == null || _activeContract == null) {
      return Scaffold(
        body: Center(child: Text(_loadingMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trọ của tôi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Xin chào, ${widget.currentUser!.name}!",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Thông tin phòng
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phòng đang thuê",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Text("Tên phòng: ${_rentedRoom!.title}"),
                    Text("Địa chỉ: ${_rentedRoom!.address}"),
                    Text(
                      "Giá thuê: ${NumberFormat.currency(locale: 'vi').format(_rentedRoom!.price)}/tháng",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hoạt động sửa chữa gần đây (thay thế phần Thông báo)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoạt động sửa chữa gần đây', // Tiêu đề mới
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('phieu_sua')
                          .where('roomId', isEqualTo: _rentedRoom!.id)
                          .orderBy('ngaySua', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          print("Lỗi StreamBuilder hoạt động gần đây: ${snapshot.error}");
                          return Text('Lỗi tải hoạt động: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('Không có hoạt động sửa chữa gần đây.');
                        }

                        final List<PhieuSuaChua> recentPhieuSuaChua = snapshot.data!.docs
                            .map((doc) => PhieuSuaChua.fromFirestore(doc, null))
                            .toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentPhieuSuaChua.length,
                          itemBuilder: (context, index) {
                            final phieu = recentPhieuSuaChua[index];
                            String activityMessage = 'Phiếu sửa chữa #${phieu.id!.substring(0, 8)}: Trạng thái ${phieu.statusText} - ${DateFormat('dd/MM/yyyy').format(phieu.ngaySua)}';

                            return ListTile(
                              title: Text(activityMessage),
                              subtitle: Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi').format(phieu.tongTien)}'),
                              onTap: () => _showPhieuSuaChuaDetailDialog(phieu),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Yêu cầu sửa chữa (Chờ xử lý)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yêu cầu sửa chữa (Chờ xử lý)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_requestList.isEmpty)
                      const Text('Không có yêu cầu chờ xử lý nào.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _requestList.length,
                        itemBuilder: (context, index) {
                          final request = _requestList[index];
                          final relatedPhieu = _phieuSuaChuaList.firstWhere(
                            (phieu) => phieu.requestId == request.id,
                            orElse: () => PhieuSuaChua(
                              id: null,
                              roomId: _rentedRoom!.id,
                              tenantId: widget.currentUser!.id,
                              ngaySua: DateTime.now(),
                              tongTien: 0,
                              status: RepairStatus.pending,
                              faultSource: FaultSource.tenant,
                              items: [],
                            ),
                          );
                          return ListTile(
                            title: Text('Yêu cầu #${request.id.substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mô tả: ${request.moTa}'),
                                Text('Trạng thái: ${request.status != null ? request.statusText : "Đã gửi yêu cầu"}'),
                                if (relatedPhieu.id != null)
                                  Text(
                                    'Phiếu sửa chữa: #${relatedPhieu.id!.substring(0, 8)}',
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Yêu cầu đã hủy (Mục mới)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yêu cầu đã hủy',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_cancelledRequestList.isEmpty)
                      const Text('Không có yêu cầu nào bị hủy.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cancelledRequestList.length,
                        itemBuilder: (context, index) {
                          final request = _cancelledRequestList[index];
                          return ListTile(
                            title: Text('Yêu cầu #${request.id.substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mô tả: ${request.moTa}'),
                                Text('Trạng thái: ${request.statusText}'),
                                Text('Thời gian hủy: ${DateFormat('dd/MM/yyyy').format(request.thoiGian)}'),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Phiếu sửa chữa (Đây là danh sách đầy đủ, không phải thông báo)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tất cả Phiếu sửa chữa',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_phieuSuaChuaList.isEmpty)
                      const Text('Không có phiếu sửa chữa nào.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _phieuSuaChuaList.length,
                        itemBuilder: (context, index) {
                          final phieu = _phieuSuaChuaList[index];
                          return ListTile(
                            title: Text('Phiếu #${phieu.id!.substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày: ${DateFormat('dd/MM/yyyy').format(phieu.ngaySua)}'),
                                Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi').format(phieu.tongTien)}'),
                                Text('Trạng thái: ${phieu.statusText}'),
                                Text('Nguồn lỗi: ${phieu.faultSourceText}'),
                                if (phieu.requestId != null)
                                  Text('Yêu cầu: #${phieu.requestId!.substring(0, 8)}'),
                              ],
                            ),
                            onTap: () => _showPhieuSuaChuaDetailDialog(phieu),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hóa đơn
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hóa đơn tháng này',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_currentBill == null)
                      const Text('Không có hóa đơn.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tháng: ${_currentBill!.thangNam}'),
                          Text(
                            'Tổng tiền: ${NumberFormat.currency(locale: 'vi').format(_currentBill!.sumPrice)}',
                          ),
                          const Text(
                            '(*Bao gồm phí sửa chữa nếu bạn chịu trách nhiệm)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nút tạo yêu cầu
            Text(
              'Yêu cầu dịch vụ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text('Sửa chữa'),
                  onPressed: () => _showCreateRequestDialog(RequestType.suaChua),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Trả phòng'),
                  onPressed: () => _showCreateRequestDialog(RequestType.traPhong),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}