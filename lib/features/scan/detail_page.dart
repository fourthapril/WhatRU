import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// โมเดลผลการสแกน
// เก็บข้อมูลทั้งหมดที่ได้จากเอนจินสแกน
// ─────────────────────────────────────────────
class ScanResult {
  final String fileHash;
  final String detectedType;   // ประเภทไฟล์จริงจาก magic bytes เช่น "PDF"
  final String routeTaken;     // "archive" | "executable" | "document" | "media" | "script" | "unknown"
  final bool extensionMatch;   // นามสกุลไฟล์ตรงกับ magic bytes หรือไม่
  final List<String> findings; // รายการผลการตรวจจับที่อ่านเข้าใจได้
  final int score;             // 0-100
  final String status;         // "Safe" | "Warning" | "Threat"
  final bool vtFound;
  final int vtMalicious;
  final int vtTotal;

  ScanResult({
    required this.fileHash,
    required this.detectedType,
    required this.routeTaken,
    required this.extensionMatch,
    required this.findings,
    required this.score,
    required this.status,
    required this.vtFound,
    required this.vtMalicious,
    required this.vtTotal,
  });
}

// ─────────────────────────────────────────────
// หน้ารายละเอียดผลสแกน
// รับข้อมูลไฟล์จาก scan_page, รันทุกสเตจการสแกน, แล้วแสดงผล
// ─────────────────────────────────────────────
class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  // ── สถานะภายในหน้าสแกน ──
  bool _isScanning = true;
  String _scanStage = 'Generating file fingerprint...';
  ScanResult? _result;
  String? _error;

  // ── พารามิเตอร์ที่ส่งมาจาก scan_page ──
  late String _fileName;
  late String _fileSize;
  late String _filePath;
  late bool _isDeepScan;
  late String _apiKey;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // อ่านอาร์กิวเมนต์ที่นี่ — ไม่ใช่ใน initState
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _fileName  = args['fileName']  ?? 'Unknown File';
    _fileSize  = args['fileSize']  ?? '';
    _filePath  = args['filePath']  ?? '';
    _isDeepScan = args['isDeepScan'] ?? false;
    _apiKey    = args['apiKey']    ?? '';

    // เริ่มสแกนทันที
    _runFullScan();
  }

  // ─────────────────────────────────────────────
  // สเตจ 1 — สร้างลายนิ้วมือไฟล์
  // สร้าง SHA-256 และตรวจสอบประเภทไฟล์จริง
  // จาก magic bytes
  // ─────────────────────────────────────────────
  String _generateHash(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  // คืนค่า string ประเภทไฟล์ที่ตรวจพบจาก magic bytes
  String _detectFileType(List<int> bytes) {
    if (bytes.length < 4) return 'UNKNOWN';

    // PDF: %PDF
    if (bytes[0] == 0x25 && bytes[1] == 0x50 &&
        bytes[2] == 0x44 && bytes[3] == 0x46) return 'PDF';

    // ZIP / DOCX / XLSX / APK (all ZIP-based): PK
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) return 'ZIP';

    // EXE / DLL: MZ
    if (bytes[0] == 0x4D && bytes[1] == 0x5A) return 'EXE';

    // ELF (Linux executable)
    if (bytes[0] == 0x7F && bytes[1] == 0x45 &&
        bytes[2] == 0x4C && bytes[3] == 0x46) return 'ELF';

    // JPG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'JPG';

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) return 'PNG';

    // MP4 / MOV: ftyp at offset 4
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 &&
        bytes[6] == 0x79 && bytes[7] == 0x70) return 'MP4';

    // ไฟล์ข้อความ/สคริปต์ — ไม่มี magic bytes, ตรวจสอบว่าเป็น ASCII ที่อ่านได้หรือไม่
    final sample = bytes.take(512).toList();
    final nonAscii = sample.where((b) => b < 9 || (b > 13 && b < 32)).length;
    if (nonAscii < 10) return 'TEXT';

    return 'UNKNOWN';
  }

  // ตรวจสอบว่านามสกุลไฟล์ตรงกับประเภทที่ตรวจพบหรือไม่
  bool _extensionMatchesType(String fileName, String detectedType) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    switch (detectedType) {
      case 'PDF':  return ext == 'pdf';
      case 'ZIP':  return ['zip', 'docx', 'xlsx', 'apk', 'jar', 'xpi'].contains(ext);
      case 'EXE':  return ['exe', 'dll', 'scr', 'com'].contains(ext);
      case 'ELF':  return ['elf', 'so', ''].contains(ext);
      case 'JPG':  return ['jpg', 'jpeg'].contains(ext);
      case 'PNG':  return ext == 'png';
      case 'MP4':  return ['mp4', 'mov', 'm4v'].contains(ext);
      case 'TEXT': return ['txt', 'js', 'ps1', 'sh', 'bat', 'vbs', 'py', 'rb', 'php'].contains(ext);
      default:     return true; // ประเภทไม่ทราบ — ไม่หักคะแนน
    }
  }

  // ─────────────────────────────────────────────
  // สเตจ 2 — สแกนตามเส้นทางประเภทไฟล์
  // ─────────────────────────────────────────────

  // ── เส้นทางแอคไคฟ์: ZIP / APK / DOCX / XLSX ──
  List<String> _scanArchive(String filePath, String ext) {
    final findings = <String>[];
    try {
      final bytes = File(filePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileNames = archive.map((f) => f.name.toLowerCase()).toList();

      if (ext == 'apk') {
        // ตรวจสอบ AndroidManifest.xml ว่ามี permission อันตรายหรือไม่
        final manifest = archive.findFile('AndroidManifest.xml');
        if (manifest != null) {
          final content = String.fromCharCodes(manifest.content as List<int>);
          final dangerousPermissions = [
            'READ_SMS', 'RECEIVE_SMS', 'SEND_SMS',
            'RECEIVE_BOOT_COMPLETED', 'READ_CONTACTS',
            'ACCESS_FINE_LOCATION', 'CAMERA',
            'RECORD_AUDIO', 'READ_CALL_LOG',
          ];
          for (final perm in dangerousPermissions) {
            if (content.contains(perm)) {
              findings.add('APK requests dangerous permission: $perm');
            }
          }
        }
      } else if (ext == 'docx' || ext == 'xlsx') {
        // ตรวจหามาโคร (vbaProject.bin)
        if (fileNames.any((n) => n.contains('vbaproject.bin'))) {
          findings.add('Office macro detected (vbaProject.bin) — high ransomware risk');
        }
      }

      // ตรวจหาสตริปต์ซ่อนอยู่ใน archive ทุกชนิด
      // ── วิธีแก้: สแกนสคริปต์ที่อยู่ใน whitelist อย่างลึก ──
      final scriptExtensions = ['.vbs', '.js', '.bat', '.exe', '.ps1', '.sh'];
      bool foundSuspiciousScript = false;

      for (final file in archive) { // สังเกตว่าเราวนลูปบนอ็อบเจกต์ไฟล์จริง ไม่ใช่แค่ชื่อเท่านั้น
        final name = file.name.toLowerCase();

        // 1. เป็น asset เว็บที่อนุญาตไว้หรือไม่?
        final isExpectedAsset = ext == 'apk' && 
                               (name.startsWith('assets/') || name.startsWith('res/')) && 
                               (name.endsWith('.js') || name.endsWith('.html'));

        if (isExpectedAsset) {
          // อย่าแค่ 'continue' อย่างเดียว เพราะแฮกเกอร์ซ่อนภัยอยู่ตรงนี้!
          // Instead, read the contents of this specific file and run your script scanner on it.
          final fileBytes = file.content as List<int>;
          final scriptFindings = _scanScript(fileBytes); 
          
          if (scriptFindings.isNotEmpty) {
            findings.add('Malicious code found hidden inside expected asset ($name): ${scriptFindings.first}');
          }
          continue;
        }

        // 2. ค้นหาสตริปต์ที่อยู่นอกบริบทจริง
        for (final scriptExt in scriptExtensions) {
          if (name.endsWith(scriptExt)) {
            findings.add('Archive contains suspicious script: $name');
            foundSuspiciousScript = true;
            break; 
          }
        }

        if (foundSuspiciousScript) break; 
      }
    } catch (e) {
      findings.add('Could not fully inspect archive contents');
    }
    return findings;
  }

  // ── เส้นทางไฟล์ปฏิบัติการ: EXE / DLL / ELF ──
  List<String> _scanExecutable(List<int> bytes) {
    final findings = <String>[];

    // สกัดข้อความที่อ่านได้จากไบนารี
    final buffer = StringBuffer();
    final strings = <String>[];
    for (final byte in bytes) {
      if (byte >= 32 && byte < 127) {
        buffer.writeCharCode(byte);
      } else {
        final s = buffer.toString();
        if (s.length >= 6) strings.add(s);
        buffer.clear();
      }
    }

    // ตรวจหาที่อยู่ IP ที่ฝังอยู่ในโค้ด
    final ipRegex = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
    final ips = strings.where((s) => ipRegex.hasMatch(s)).toList();
    if (ips.isNotEmpty) {
      findings.add('Hardcoded IP address found: ${ips.first}');
    }

    // ตรวจหาลิงก์ที่น่าสงสัย
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final urls = strings.where((s) => urlRegex.hasMatch(s)).toList();
    if (urls.isNotEmpty) {
      findings.add('Hardcoded URL found in binary: ${urls.first}');
    }

    // คำนวณเอนโทรปี (Shannon entropy)
    final entropy = _calculateEntropy(bytes);
    if (entropy > 7.2) {
      findings.add(
        'High entropy detected (${entropy.toStringAsFixed(2)}/8.0) — file may be packed or encrypted',
      );
    }

    return findings;
  }

  // Shannon entropy calculation
  double _calculateEntropy(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    final freq = <int, int>{};
    for (final b in bytes) {
      freq[b] = (freq[b] ?? 0) + 1;
    }
    double entropy = 0;
    for (final count in freq.values) {
      final p = count / bytes.length;
      entropy -= p * (log(p) / log(2));
    }
    return entropy;
  }

  // ── เส้นทางเอกสาร: PDF ──
  List<String> _scanPdf(List<int> bytes) {
    final findings = <String>[];
    final content = String.fromCharCodes(
      bytes.where((b) => b >= 32 && b < 127),
    );

    // ตรวจหาป้าย PDF ที่อาจเป็นอันตราย
    final maliciousTags = ['/JavaScript', '/JS', '/OpenAction', '/AA', '/Launch'];
    for (final tag in maliciousTags) {
      if (content.contains(tag)) {
        findings.add('Malicious PDF tag found: $tag — PDF may execute code automatically');
      }
    }

    // ตรวจ Polyglot — ขยะก่อน %PDF ใน 1024 ไบต์แรก
    final header = String.fromCharCodes(bytes.take(1024));
    final pdfOffset = header.indexOf('%PDF');
    if (pdfOffset > 10) {
      findings.add(
        'Polyglot detected — %PDF marker found at offset $pdfOffset (not at file start)',
      );
    }

    return findings;
  }

  // ── เส้นทางสื่อ: JPG / PNG / MP4 ──
  List<String> _scanMedia(List<int> bytes, String detectedType) {
    final findings = <String>[];

    // ค้นหาเครื่องหมายจบไฟล์ที่ถูกต้อง
    int? eofOffset;

    if (detectedType == 'JPG') {
      // จบไฟล์ JPEG: FF D9
      for (int i = bytes.length - 2; i >= 0; i--) {
        if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
          eofOffset = i + 2;
          break;
        }
      }
    } else if (detectedType == 'PNG') {
      // จบไฟล์ PNG: ชิ้นส่วน IEND (49 45 4E 44 AE 42 60 82)
      for (int i = bytes.length - 8; i >= 0; i--) {
        if (bytes[i] == 0x49 && bytes[i + 1] == 0x45 &&
            bytes[i + 2] == 0x4E && bytes[i + 3] == 0x44) {
          eofOffset = i + 8;
          break;
        }
      }
    }

    if (eofOffset != null && eofOffset < bytes.length) {
      final trailingBytes = bytes.length - eofOffset;
      if (trailingBytes > 512) {
        // More than 512 bytes of trailing data is suspicious
        final trailingKB = (trailingBytes / 1024).toStringAsFixed(1);
        findings.add(
          'Trailing data detected: ${trailingKB}KB of data after end-of-image marker — possible hidden payload',
        );
      }
    }

    return findings;
  }

  // ── เส้นทางสคริปต์: TXT / JS / PS1 / SH / BAT ──
  List<String> _scanScript(List<int> bytes) {
    // ── ข้ามไฟล์ที่รู้จักว่าเป็นของดีแล้ว (เช่น ad-tracker ทั่วไป) โดยใช้แฮชตรง
    final knownGoodHashes = [
      'put_real_hash_of_mraid_js_here', 
      'put_real_hash_of_omsdk_js_here',
    ];

    final currentFileHash = sha256.convert(bytes).toString();
    if (knownGoodHashes.contains(currentFileHash)) return []; 

    final findings = <String>[];
    final content = String.fromCharCodes(
      bytes.where((b) => b >= 32 && b <= 126),
    );

    // ── มองหา Base64 ก้อนใหญ่ (อาจเป็น payload ซ่อน หรือแค่นรูปภาพ)
    final base64Regex = RegExp(r'[A-Za-z0-9+/]{100,}={0,2}');
    final bool hasBase64 = base64Regex.hasMatch(content);

    // ── ตรวจสอบว่าสคริปต์มีคำสั่งที่ใช้แฮ็คระบบหรือไม่
    final dangerousPatterns = [
      'eval(', 'Invoke-Expression', 'IEX(', 'WScript.Shell',
      'ActiveXObject', 'cmd.exe', 'powershell -enc',
      'base64_decode', 'exec(', 'system(',
    ];
    
    bool hasDangerousCommand = false;
    String? foundCommand;
    for (final pattern in dangerousPatterns) {
      if (content.toLowerCase().contains(pattern.toLowerCase())) {
        hasDangerousCommand = true;
        foundCommand = pattern;
        break; 
      }
    }

    // ── คำนวณว่าที่ไฟล์มีอักขระพิเศษมากเกินไปหรือไม่ (สัญญาณการปกปิดของแฮกเกอร์)
    final int specialChars = content.length > 100
        ? content.runes.where((r) => '[]()!+{}^%\$#@*'.contains(String.fromCharCode(r))).length
        : 0;
    final double obfuscationRatio = content.length > 100 
        ? specialChars / content.length 
        : 0;
    final bool isHeavilyObfuscated = obfuscationRatio > 0.4;

    // ── ตีความว่าเป็นภัยคุกคาม: Base64 payload ถูกใช้ร่วมกับคำสั่งที่ถูกแฮ็ก
    if (hasBase64 && hasDangerousCommand) {
      findings.add('High Threat: $foundCommand combined with large Base64 blocks.');
    } 
    // ── ตีความว่าเป็นภัยคุกคาม: คำสั่งโจมตีซ่อนอยู่ในข้อความขยะ
    else if (hasDangerousCommand && isHeavilyObfuscated) {
      findings.add('High Threat: $foundCommand disguised within heavily obfuscated code.');
    } 
    // ── ตีความว่าเป็นภัยคุกคาม: ปกปิดหนักร่วมกับ payload ที่เข้ารหัส
    else if (isHeavilyObfuscated && hasBase64) {
      findings.add('High Threat: Heavy obfuscation combined with encoded Base64 payload.');
    } 
    // ── เตือนอ่อนๆ: ใช้ eval() หรือ ActiveX แบบปกติ ไม่ได้ปกปิดมาก
    else if (hasDangerousCommand && !isHeavilyObfuscated && !hasBase64) {
      findings.add('Suspicious command found: $foundCommand');
    }

    return findings;
  }

  // ─────────────────────────────────────────────
  // สเตจ 3 — VIRUSTOTAL (เฉพาะ Deep Scan)
  // สร้าง SHA-256 ก่อน แล้วอัปโหลดไฟล์ถ้าไม่เจอในฐานข้อมูล
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _runVirusTotal(
    String hash,
    String filePath,
    String apiKey,
  ) async {
    // ขั้นตอนที่ 1: ตรวจสอบแฮช
    final hashResponse = await http.get(
      Uri.parse('https://www.virustotal.com/api/v3/files/$hash'),
      headers: {'x-apikey': apiKey},
    );

    if (hashResponse.statusCode == 200) {
      // เจอในฐานข้อมูล
      final data = jsonDecode(hashResponse.body);
      final stats = data['data']['attributes']['last_analysis_stats'];
      final int malicious  = stats['malicious']  ?? 0;
      final int suspicious = stats['suspicious'] ?? 0;
      final int undetected = stats['undetected'] ?? 0;
      final int harmless   = stats['harmless']   ?? 0;
      final int total = malicious + suspicious + undetected + harmless;
      return {
        'found': true,
        'malicious': malicious,
        'suspicious': suspicious,
        'total': total,
      };
    }

    if (hashResponse.statusCode == 404) {
      // ไม่เจอในฐานข้อมูล — อัปโหลดไฟล์
      setState(() => _scanStage = 'Uploading file to VirusTotal...');
      try {
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('https://www.virustotal.com/api/v3/files'),
        )
          ..headers['x-apikey'] = apiKey
          ..files.add(await http.MultipartFile.fromPath('file', filePath));

        final uploadResponse = await uploadRequest.send();
        final uploadBody = await uploadResponse.stream.bytesToString();

        if (uploadResponse.statusCode == 200) {
          final uploadData = jsonDecode(uploadBody);
          final analysisId = uploadData['data']['id'];

          // ตรวจสอบผลเป็นระยะ (สูงสุด 30 วินาที)
          setState(() => _scanStage = 'Waiting for VirusTotal analysis...');
          for (int i = 0; i < 6; i++) {
            await Future.delayed(const Duration(seconds: 5));
            final analysisResponse = await http.get(
              Uri.parse('https://www.virustotal.com/api/v3/analyses/$analysisId'),
              headers: {'x-apikey': apiKey},
            );
            if (analysisResponse.statusCode == 200) {
              final analysisData = jsonDecode(analysisResponse.body);
              final status = analysisData['data']['attributes']['status'];
              if (status == 'completed') {
                final stats = analysisData['data']['attributes']['stats'];
                final int malicious  = stats['malicious']  ?? 0;
                final int suspicious = stats['suspicious'] ?? 0;
                final int undetected = stats['undetected'] ?? 0;
                final int harmless   = stats['harmless']   ?? 0;
                final int total = malicious + suspicious + undetected + harmless;
                return {
                  'found': true,
                  'malicious': malicious,
                  'suspicious': suspicious,
                  'total': total,
                };
              }
            }
          }
          // รอเกินเวลาแล้ว
          return {'found': false, 'malicious': 0, 'suspicious': 0, 'total': 0};
        }
      } catch (_) {
        return {'found': false, 'malicious': 0, 'suspicious': 0, 'total': 0};
      }
    }

    if (hashResponse.statusCode == 401) {
      throw Exception('Invalid VirusTotal API key');
    }

    return {'found': false, 'malicious': 0, 'suspicious': 0, 'total': 0};
  }

  // ─────────────────────────────────────────────
  // สเตจ 4 — คำนวณคะแนน
  // ─────────────────────────────────────────────
  int _calculateScore(
    bool extensionMatch,
    List<String> findings,
    Map<String, dynamic>? vtResult,
  ) {
    int score = 100;

    // นามสกุลไม่ตรงประเภท
    if (!extensionMatch) score -= 20;

    // ลดคะแนนตามแต่ละผลการตรวจพบ
    for (final finding in findings) {
      if (finding.contains('macro'))                  score -= 40;
      else if (finding.contains('OpenAction') ||
               finding.contains('JavaScript'))        score -= 40;
      else if (finding.contains('Polyglot'))          score -= 30;
      else if (finding.contains('dangerous permission')) score -= 30;
      else if (finding.contains('packed or encrypted'))  score -= 30;
      else if (finding.contains('Trailing data'))     score -= 25;
      else if (finding.contains('Hardcoded IP') ||
               finding.contains('Hardcoded URL'))     score -= 25;
      else if (finding.contains('Dangerous command')) score -= 35;
      else if (finding.contains('Base64'))            score -= 20;
      else if (finding.contains('obfuscation'))       score -= 25;
      else if (finding.contains('script file'))       score -= 30;
      else                                            score -= 15;
    }

    // ลดคะแนนจาก VirusTotal
    if (vtResult != null && vtResult['found'] == true) {
      final int malicious = vtResult['malicious'] ?? 0;
      if (malicious >= 10)     score -= 60;
      else if (malicious >= 4) score -= 40;
      else if (malicious >= 1) score -= 20;
    }

    return score.clamp(0, 100);
  }

  String _scoreToStatus(int score) {
    if (score >= 80) return 'Safe';
    if (score >= 50) return 'Warning';
    return 'Threat';
  }

  // ─────────────────────────────────────────────
  // สเตจ 5 — บันทึกลง Firestore
  // ประวัติการสแกน + สถิติรายสัปดาห์ + แจ้งเตือน
  // ─────────────────────────────────────────────
  Future<void> _saveToFirestore(ScanResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // ── บันทึกประวัติการสแกน ──
    await userDoc.collection('scanHistory').add({
      'fileName':         _fileName,
      'fileSize':         _fileSize,
      'fileHash':         result.fileHash,
      'score':            result.score,
      'status':           result.status,
      'fileType':         result.detectedType,
      'routeTaken':       result.routeTaken,
      'isDeepScan':       _isDeepScan,
      'extensionMatch':   result.extensionMatch,
      'specificFindings': result.findings,
      'vtFound':          result.vtFound,
      'vtMalicious':      result.vtMalicious,
      'vtTotal':          result.vtTotal,
      'scannedAt':        FieldValue.serverTimestamp(),
    });

    // ── ปรับปรุงสถิติประจำสัปดาห์ ──
    final now = DateTime.now();
    // รูปแบบรหัสสัปดาห์: "2026-W15"
    final weekNumber = _getWeekNumber(now);
    final weekId = '${now.year}-W$weekNumber';

    final weekDoc = userDoc.collection('weeklyStats').doc(weekId);
    final weekSnap = await weekDoc.get();

    if (!weekSnap.exists) {
      // สร้างเอกสารของสัปดาห์ใหม่
      final weekStart = _getWeekStart(now);
      await weekDoc.set({
        'weekStart':    Timestamp.fromDate(weekStart),
        'weekEnd':      Timestamp.fromDate(weekStart.add(const Duration(days: 7))),
        'totalScans':   1,
        'averageScore': result.score,
        'threatCount':  result.status == 'Threat'  ? 1 : 0,
        'warningCount': result.status == 'Warning' ? 1 : 0,
        'safeCount':    result.status == 'Safe'    ? 1 : 0,
      });
    } else {
      // อัปเดตสัปดาห์ที่มีอยู่ — คำนวณค่าเฉลี่ยใหม่
      final data = weekSnap.data()!;
      final int prevTotal    = data['totalScans']   ?? 0;
      final double prevAvg   = (data['averageScore'] ?? 0).toDouble();
      final int newTotal     = prevTotal + 1;
      final double newAvg    = ((prevAvg * prevTotal) + result.score) / newTotal;

      await weekDoc.update({
        'totalScans':   newTotal,
        'averageScore': newAvg.round(),
        'threatCount':  FieldValue.increment(result.status == 'Threat'  ? 1 : 0),
        'warningCount': FieldValue.increment(result.status == 'Warning' ? 1 : 0),
        'safeCount':    FieldValue.increment(result.status == 'Safe'    ? 1 : 0),
      });
    }

    // ── บันทึกไปยังการแจ้งเตือนในแอป ──
    final notifTitle = result.status == 'Threat'
        ? '⚠️ Threat Detected!'
        : result.status == 'Warning'
            ? '⚡ Warning'
            : '✅ Scan Complete';

    final notifMessage = result.status == 'Threat'
        ? '$_fileName flagged as threat (${result.score}/100). Check results.'
        : result.status == 'Warning'
            ? '$_fileName has suspicious findings (${result.score}/100).'
            : '$_fileName is safe (${result.score}/100).';

    await userDoc.collection('notifications').add({
      'title':     notifTitle,
      'message':   notifMessage,
      'type':      result.status == 'Threat' ? 'threat' : 'scan',
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ตัวช่วยคำนวณหมายเลขสัปดาห์
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // ─────────────────────────────────────────────
  // ตัวประสานการสแกนหลัก
  // รันทุกขั้นตอนตามลำดับ
  // ─────────────────────────────────────────────
  Future<void> _runFullScan() async {
    try {
      if (_filePath.isEmpty || !File(_filePath).existsSync()) {
        setState(() {
          _error = 'File not found. It may have been moved or deleted.';
          _isScanning = false;
        });
        return;
      }

      final bytes = File(_filePath).readAsBytesSync();
      final ext = _fileName.contains('.')
          ? _fileName.split('.').last.toLowerCase()
          : '';

      // ── สเตจ 1: สร้างลายนิ้วมือ ──
      setState(() => _scanStage = 'Generating SHA-256 fingerprint...');
      final hash = _generateHash(bytes);
      final detectedType = _detectFileType(bytes);
      final extensionMatch = _extensionMatchesType(_fileName, detectedType);

      // ── สเตจ 2: สแกนตามเส้นทางไฟล์ ──
      setState(() => _scanStage = 'Analyzing file structure...');
      List<String> findings = [];
      String routeTaken = 'unknown';

      switch (detectedType) {
        case 'ZIP':
          routeTaken = 'archive';
          setState(() => _scanStage = 'Inspecting archive contents...');
          findings = _scanArchive(_filePath, ext);
          break;
        case 'EXE':
        case 'ELF':
          routeTaken = 'executable';
          setState(() => _scanStage = 'Analyzing executable strings and entropy...');
          findings = _scanExecutable(bytes);
          break;
        case 'PDF':
          routeTaken = 'document';
          setState(() => _scanStage = 'Scanning PDF for malicious tags...');
          findings = _scanPdf(bytes);
          break;
        case 'JPG':
        case 'PNG':
        case 'MP4':
          routeTaken = 'media';
          setState(() => _scanStage = 'Checking for trailing data...');
          findings = _scanMedia(bytes, detectedType);
          break;
        case 'TEXT':
          routeTaken = 'script';
          setState(() => _scanStage = 'Scanning script for dangerous patterns...');
          findings = _scanScript(bytes);
          break;
        default:
          routeTaken = 'unknown';
          findings = [];
      }

      // ── สเตจ 3: VirusTotal (เฉพาะ Deep Scan) ──
      Map<String, dynamic>? vtResult;
      if (_isDeepScan && _apiKey.isNotEmpty) {
        setState(() => _scanStage = 'Checking VirusTotal database...');
        try {
          vtResult = await _runVirusTotal(hash, _filePath, _apiKey);
        } catch (e) {
          // API key ไม่ถูกต้อง — แสดงเป็นผลการตรวจพบแต่ไม่แครช
          findings.add('VirusTotal check failed: ${e.toString()}');
        }
      }

      // ── สเตจ 4: คำนวณคะแนน ──
      final score = _calculateScore(extensionMatch, findings, vtResult);
      final status = _scoreToStatus(score);

      final result = ScanResult(
        fileHash:      hash,
        detectedType:  detectedType,
        routeTaken:    routeTaken,
        extensionMatch: extensionMatch,
        findings:      findings,
        score:         score,
        status:        status,
        vtFound:       vtResult?['found'] ?? false,
        vtMalicious:   vtResult?['malicious'] ?? 0,
        vtTotal:       vtResult?['total'] ?? 0,
      );

      // ── สเตจ 5: บันทึกผลลง Firestore ──
      setState(() => _scanStage = 'Saving results...');
      await _saveToFirestore(result);

      // ── Done ──
      setState(() {
        _result = result;
        _isScanning = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Scan failed: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // บันทึกลง StrongBox
  // ─────────────────────────────────────────────
  Future<void> _saveToStrongBox() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('Please log in to save to StrongBox', isError: true);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('strongBox')
          .add({
        'fileName':     _fileName,
        'fileSize':     _fileSize,
        'filePath':     _filePath,
        'fileHash':     _result!.fileHash,
        'score':        _result!.score,
        'status':       _result!.status,
        'savedAt':      FieldValue.serverTimestamp(),
        'lastVerified': FieldValue.serverTimestamp(),
      });
      _showSnackbar('Saved to StrongBox!');
    } catch (e) {
      _showSnackbar('Failed to save: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFFF4B6C) : const Color(0xFF00FFB2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ตัวช่วย UI
  // ─────────────────────────────────────────────
  IconData _getFileIcon(String fileName, String detectedType) {
    switch (detectedType) {
      case 'PDF':  return Icons.picture_as_pdf;
      case 'EXE':
      case 'ELF':  return Icons.terminal;
      case 'ZIP':  return Icons.folder_zip;
      case 'JPG':
      case 'PNG':  return Icons.image;
      case 'MP4':  return Icons.movie;
      case 'TEXT': return Icons.code;
      default:     return Icons.insert_drive_file;
    }
  }

  Color get _scoreColor {
    if (_result == null) return Colors.grey;
    if (_result!.score >= 80) return const Color(0xFF00FFB2);
    if (_result!.score >= 50) return Colors.amber;
    return const Color(0xFFFF4B6C);
  }

  // ─────────────────────────────────────────────
  // สร้าง UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Result',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isScanning
          ? _buildScanningState()
          : _error != null
              ? _buildErrorState()
              : _buildResultState(),
    );
  }

  // ── สถานะการสแกน — แสดงขณะกำลังสแกน ──
  Widget _buildScanningState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // วงแสดงสถานะสแกนเคลื่อนไหว
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FFB2).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FFB2),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              _fileName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            Text(
              _scanStage,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            if (_isDeepScan)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFB2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEEP SCAN',
                  style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── สถานะข้อผิดพลาด ──
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFFF4B6C), size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isScanning = true;
                  _error = null;
                  _scanStage = 'Retrying...';
                });
                _runFullScan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFB2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── สถานะผลลัพธ์ — แสดงหลังการสแกนเสร็จ ──
  Widget _buildResultState() {
    final result = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ส่วนหัวข้อมูลไฟล์ ──
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _scoreColor, width: 4),
                    color: _scoreColor.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Icon(
                      _getFileIcon(_fileName, result.detectedType),
                      size: 40,
                      color: _scoreColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _fileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _fileSize,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // แถวป้ายสถานะ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(result.detectedType, Colors.blue),
                    if (!result.extensionMatch) ...[
                      const SizedBox(width: 8),
                      _buildBadge('TYPE MISMATCH', Colors.orange),
                    ],
                    if (_isDeepScan) ...[
                      const SizedBox(width: 8),
                      _buildBadge('DEEP SCAN', const Color(0xFF00FFB2)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── การ์ดคะแนน ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _scoreColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Safety Score',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      result.status.toUpperCase(),
                      style: TextStyle(
                        color: _scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.routeTaken.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${result.score}',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor,
                        ),
                      ),
                      const TextSpan(
                        text: '/100',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── แฮช SHA-256 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHA-256',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  result.fileHash,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── การประเมินความเสี่ยง ──
          const Text(
            'Risk Assessment',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 16),

          // ตรวจสอบความตรงของนามสกุล
          _buildAssessmentItem(
            'File Type Verification',
            result.extensionMatch
                ? 'Extension matches detected type (${result.detectedType})'
                : 'Extension does not match detected type (${result.detectedType})',
            result.extensionMatch ? 'Safe' : 'Warning',
            result.extensionMatch
                ? const Color(0xFF00FFB2)
                : Colors.orange,
            result.extensionMatch
                ? Icons.check_circle
                : Icons.warning_amber_rounded,
          ),

          // ผลการตรวจเจอตามเส้นทางเฉพาะ
          if (result.findings.isEmpty)
            _buildAssessmentItem(
              '${result.routeTaken[0].toUpperCase()}${result.routeTaken.substring(1)} Analysis',
              'No suspicious patterns detected',
              'Safe',
              const Color(0xFF00FFB2),
              Icons.check_circle,
            )
          else
            ...result.findings.map((finding) => _buildAssessmentItem(
                  'Finding',
                  finding,
                  'Alert',
                  const Color(0xFFFF4B6C),
                  Icons.dangerous,
                )),

          // ผลจาก VirusTotal
          if (_isDeepScan)
            _buildAssessmentItem(
              'VirusTotal Multi-Engine',
              result.vtFound
                  ? '${result.vtMalicious}/${result.vtTotal} engines flagged this file'
                  : 'File not found in VirusTotal database',
              result.vtFound && result.vtMalicious > 0 ? 'Threat' : 'Safe',
              result.vtFound && result.vtMalicious > 0
                  ? const Color(0xFFFF4B6C)
                  : const Color(0xFF00FFB2),
              result.vtFound && result.vtMalicious > 0
                  ? Icons.dangerous
                  : Icons.check_circle,
            ),

          // คำเตือน Deep Scan สำหรับผู้ใช้แบบพื้นฐาน
          if (!_isDeepScan)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.grey, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enable Deep Scan with a VirusTotal API key for multi-engine threat detection.',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── ปุ่มบันทึกลง StrongBox ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveToStrongBox,
              icon: const Icon(Icons.lock_outline, color: Colors.black),
              label: const Text(
                'Save to StrongBox',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFB2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAssessmentItem(
    String title,
    String subtitle,
    String status,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}