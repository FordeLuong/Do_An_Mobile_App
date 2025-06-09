import 'package:do_an_cuoi_ki/models/compensations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CompensationListScreen extends StatefulWidget {
  final String contractId;

  const CompensationListScreen({Key? key, required this.contractId}) 
      : super(key: key);

  @override
  _CompensationListScreenState createState() => _CompensationListScreenState();
}

class _CompensationListScreenState extends State<CompensationListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Bồi thường'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('compensations')
            .where('ContactID', isEqualTo: widget.contractId)
            // .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có dữ liệu bồi thường'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index] as DocumentSnapshot<Map<String, dynamic>>;
              final compensation = CompensationModel.fromFirestore(doc, null);

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(
                    'Ngày: ${_dateFormat.format(compensation.date)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Tổng tiền: ${_currencyFormat.format(compensation.totalAmount)}',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (compensation.violationTerms.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Số điều khoản vi phạm: ${compensation.violationTerms.length}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompensationDetailScreen(
                          compensation: compensation,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CompensationDetailScreen extends StatelessWidget {
  final CompensationModel compensation;

  const CompensationDetailScreen({Key? key, required this.compensation}) 
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Bồi thường'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin chung
            _buildInfoCard(
              context,
              title: 'Thông tin chung',
              children: [
                _buildInfoRow('Ngày tạo:', dateFormat.format(compensation.createdAt)),
                _buildInfoRow('Ngày bồi thường:', dateFormat.format(compensation.date)),
                _buildInfoRow(
                  'Tổng số tiền:', 
                  currencyFormat.format(compensation.totalAmount),
                  isAmount: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Các điều khoản vi phạm
            if (compensation.violationTerms.isNotEmpty) ...[
              _buildInfoCard(
                context,
                title: 'Điều khoản vi phạm',
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: compensation.violationTerms
                        .map((term) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                '• $term',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Danh sách các khoản bồi thường
            _buildInfoCard(
              context,
              title: 'Chi tiết bồi thường',
              children: [
                ...compensation.items.map((item) => _buildCompensationItem(
                      context,
                      item: item,
                      currencyFormat: currencyFormat,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, 
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: isAmount
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationItem(
    BuildContext context, {
    required CompensationItem item,
    required NumberFormat currencyFormat,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.info,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(item.cost),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16, thickness: 1),
        ],
      ),
    );
  }
}