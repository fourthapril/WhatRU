import 'package:flutter/material.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/routes/app_routes.dart';

// --- โมเดลสำหรับจัดการข้อมูลประวัติการสแกน ---
class HistoryItem {
  final String title;
  final DateTime date;
  final double sizeMb;
  final int score;

  HistoryItem(this.title, this.date, this.sizeMb, this.score);

  // กำหนดสีของรายการตามระดับคะแนนความปลอดภัย
  Color get color {
    if (score >= 60) return const Color(0xFF00FFB2); 
    if (score >= 30) return Colors.amber; 
    return const Color(0xFFFF4B6C); 
  }

  // กำหนดป้ายกำกับสถานะตามระดับคะแนนความปลอดภัย
  String get status {
    if (score >= 60) return 'Safe';
    if (score >= 30) return 'Warning';
    return 'Threat';
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // ข้อมูลจำลองทั้งหมดในระบบ
  final List<HistoryItem> _allItems = [
    HistoryItem('Document_2024.pdf', DateTime(2026, 4, 12, 14, 30), 6.7, 95),
    HistoryItem('Setup_v2.exe', DateTime(2026, 4, 12, 10, 15), 34.2, 15),
    HistoryItem('Photo_backup.zip', DateTime(2026, 4, 11, 20, 0), 340.0, 100),
    HistoryItem('Unknown_Script.bat', DateTime(2026, 4, 10, 9, 45), 1.2, 45),
    HistoryItem('Project_Final.docx', DateTime(2026, 4, 8, 16, 20), 4.1, 85),
    HistoryItem('crack_tool.rar', DateTime(2026, 3, 25, 23, 10), 17.5, 20),
    HistoryItem('Presentation.pptx', DateTime(2026, 3, 20, 11, 5), 12.8, 90),
  ];

  // รายการที่ผ่านการกรองและพร้อมแสดงผล
  List<HistoryItem> _filteredItems = [];

  // ตัวแปรสำหรับจัดเก็บเงื่อนไขการกรองและการเรียงลำดับ
  String _selectedSort = 'Newest'; // Newest, Oldest, Largest, Smallest
  String _selectedStatus = 'All'; // All, Safe, Warning, Threat

  @override
  void initState() {
    super.initState();
    _applyFilter(); // เริ่มต้นโหลดและประมวลผลข้อมูล
  }

  // ฟังก์ชันสำหรับการจัดเรียงและคัดกรองข้อมูล
  void _applyFilter() {
    List<HistoryItem> temp = List.from(_allItems);

    // 1. คัดกรองตามสถานะความปลอดภัย
    if (_selectedStatus != 'All') {
      temp.retainWhere((item) => item.status == _selectedStatus);
    }

    // 2. จัดเรียงตามเงื่อนไขที่ผู้ใช้เลือก
    if (_selectedSort == 'Newest') {
      temp.sort((a, b) => b.date.compareTo(a.date)); 
    } else if (_selectedSort == 'Oldest') {
      temp.sort((a, b) => a.date.compareTo(b.date)); 
    } else if (_selectedSort == 'Largest') {
      temp.sort((a, b) => b.sizeMb.compareTo(a.sizeMb)); 
    } else if (_selectedSort == 'Smallest') {
      temp.sort((a, b) => a.sizeMb.compareTo(b.sizeMb)); 
    }

    setState(() {
      _filteredItems = temp;
    });
  }

  // ฟังก์ชันสำหรับจัดรูปแบบวันที่และเวลา
  String _formatDateTime(DateTime d) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String day = d.day.toString();
    String month = months[d.month - 1];
    String year = d.year.toString();
    String hour = d.hour.toString().padLeft(2, '0');
    String minute = d.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ElevatedButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: const Icon(Icons.filter_list, size: 16, color: Color(0xFF00FFB2)),
                  label: const Text('Filter', style: TextStyle(color: Color(0xFF00FFB2))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFB2).withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          
          // พื้นที่แสดงผลรายการ
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No files match your filter.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredItems.length + 1, // เพิ่มพื้นที่ว่างด้านล่าง
                    itemBuilder: (context, index) {
                      if (index == _filteredItems.length) {
                        return const SizedBox(height: 80); 
                      }
                      final item = _filteredItems[index];
                      String subtitle = '${_formatDateTime(item.date)}  ·  ${item.sizeMb} MB';
                      return _buildHistoryItem(context, item.title, subtitle, item.score, item.color, item.status);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ส่วนการแสดงผล Bottom Sheet สำหรับตัวกรองข้อมูล
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // อนุญาตให้ขยายความสูงได้เต็มหน้าจอ
      backgroundColor: const Color(0xFF131F1D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // ใช้ SingleChildScrollView เพื่อรองรับหน้าจอขนาดเล็ก
            return SingleChildScrollView( 
              child: Container(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  // คำนวณระยะขอบล่างป้องกันการทับซ้อนกับ Navigation Bar
                  bottom: 24 + MediaQuery.of(context).padding.bottom, 
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(2)))),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sort & Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),

                    // ตัวเลือกการเรียงลำดับ (Sort By)
                    const Text('Sort By', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('Newest', _selectedSort, (val) => setModalState(() => _selectedSort = val)),
                        _buildChip('Oldest', _selectedSort, (val) => setModalState(() => _selectedSort = val)),
                        _buildChip('Largest', _selectedSort, (val) => setModalState(() => _selectedSort = val)),
                        _buildChip('Smallest', _selectedSort, (val) => setModalState(() => _selectedSort = val)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ตัวเลือกการกรองตามสถานะ (Filter By Status)
                    const Text('Filter By Status', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('All', _selectedStatus, (val) => setModalState(() => _selectedStatus = val)),
                        _buildChip('Safe', _selectedStatus, (val) => setModalState(() => _selectedStatus = val), activeColor: const Color(0xFF00FFB2)),
                        _buildChip('Warning', _selectedStatus, (val) => setModalState(() => _selectedStatus = val), activeColor: Colors.amber),
                        _buildChip('Threat', _selectedStatus, (val) => setModalState(() => _selectedStatus = val), activeColor: const Color(0xFFFF4B6C)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ปุ่มยืนยันการตั้งค่า
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilter(); 
                          Navigator.pop(context); 
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFB2),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // วิดเจ็ตสำหรับสร้างปุ่มตัวเลือกใน Filter
  Widget _buildChip(String label, String selectedValue, Function(String) onSelected, {Color? activeColor}) {
    bool isSelected = label == selectedValue;
    Color color = activeColor ?? const Color(0xFF00FFB2);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) onSelected(label);
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: const Color(0xFF161B22),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // วิดเจ็ตสำหรับแสดงผลรายละเอียดประวัติการสแกนแต่ละรายการ
  Widget _buildHistoryItem(BuildContext context, String title, String subtitle, int score, Color color, String statusLabel) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.scanResult),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.description_outlined, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(statusLabel.toUpperCase(), style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}