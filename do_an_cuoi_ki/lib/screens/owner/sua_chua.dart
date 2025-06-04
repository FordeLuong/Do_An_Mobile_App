
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/DVSC.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



class SuaChua extends StatefulWidget {
  const SuaChua({super.key, required this.roomId, required this.tenantId});
  final String roomId;
  final String tenantId;

  @override 
  _SuaChuaState createState() => _SuaChuaState();
}

class _SuaChuaState extends State<SuaChua> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late DateTime _ngaySua;
  DonViSuaChua? _selectedDonViSuaChua;
  final List<CompensationItem> _items = [];
  final List<DonViSuaChua> _DonViSuaChuaList = [];
  bool _isLoading = true;

  final TextEditingController _itemInfoController = TextEditingController();
  final TextEditingController _itemCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ngaySua = DateTime.now();
    _loadDonViSuaChuaList();
  }

  Future<void> _loadDonViSuaChuaList() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('DonViSuaChuas')
          .get();

      setState(() {
        _DonViSuaChuaList.addAll(
          querySnapshot.docs.map((doc) => DonViSuaChua.fromFirestore(doc, null)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách nhà cung cấp: $e')),
      );
    }
  }

  void _addItem() {
    if (_itemInfoController.text.isEmpty && _itemCostController.text.isEmpty) {
      return;
    }

    setState(() {
      _items.add(
        CompensationItem(
          info: _itemInfoController.text,
          cost: double.tryParse(_itemCostController.text) ?? 0,
        ),
      );
      _itemInfoController.clear();
      _itemCostController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngaySua,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _ngaySua) {
      setState(() {
        _ngaySua = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final phieuSuaChua = PhieuSuaChua(
      roomId: widget.roomId,
      tenantId: widget.tenantId,
      DVSSId: _selectedDonViSuaChua?.id,
      items: _items.isEmpty ? null : _items,
      ngaySua: _ngaySua,
      tongTien: PhieuSuaChua.calculateTotal(_items.isEmpty ? null : _items),
      status: RepairStatus.pending
    );

    try {
      await FirebaseFirestore.instance
          .collection('phieuSuaChua')
          .add(phieuSuaChua.toFirestore());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu phiếu sửa chữa thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu phiếu sửa chữa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phiếu Sửa Chữa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thông tin cơ bản
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Ngày sửa chữa'),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(_ngaySua),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<DonViSuaChua>(
                              value: _selectedDonViSuaChua,
                              decoration: const InputDecoration(
                                labelText: 'Đơn vị sửa chữa',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<DonViSuaChua>(
                                  value: null,
                                  child: Text('Không chọn'),
                                ),
                                ..._DonViSuaChuaList.map((ncc) {
                                  return DropdownMenuItem<DonViSuaChua>(
                                    value: ncc,
                                    child: Text(ncc.ten),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDonViSuaChua = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Danh sách vật tư/hạng mục sửa chữa
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Vật tư/Hạng mục sửa chữa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _itemInfoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Mô tả',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _itemCostController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Chi phí',
                                      border: OutlineInputBorder(),
                                      prefixText: '₫',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addItem,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_items.isNotEmpty)
                              ..._items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return ListTile(
                                  title: Text(item.info),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'vi',
                                          symbol: '₫',
                                        ).format(item.cost),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    // Tổng tiền
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng tiền:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'vi',
                                symbol: '₫',
                              ).format(PhieuSuaChua.calculateTotal(_items.isEmpty ? null : _items)),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nút lưu
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('LƯU PHIẾU SỬA CHỮA'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _itemInfoController.dispose();
    _itemCostController.dispose();
    super.dispose();
  }
}