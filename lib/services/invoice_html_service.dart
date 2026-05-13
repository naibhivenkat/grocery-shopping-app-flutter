import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> generateInvoiceHtml(List<dynamic> selectedItems) async {
  // Calculate totals
  int totalQuantity = 0;
  for (final item in selectedItems) {
    totalQuantity += item.quantity as int;
  }

  // Build table rows
  final String tableRows = List.generate(
    selectedItems.length,
    (index) {
      final item = selectedItems[index];
      return '''
<tr>
  <td>${index + 1}</td>
  <td>${item.name}</td>
  <td>${item.quantity}</td>
</tr>
''';
    },
  ).join();

  // Generate HTML content
  final String html = '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Invoice</title>
<style>
  body {
    font-family: "Noto Sans Kannada", Arial, sans-serif;
    background: #f8fafc;
    margin: 0;
    padding: 24px;
    color: #1e293b;
  }

  .container {
    max-width: 900px;
    margin: 0 auto;
    background: #ffffff;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 20px 40px rgba(15, 23, 42, 0.08);
  }

  .header {
    background: linear-gradient(135deg, #1e293b, #6366f1);
    color: white;
    padding: 32px;
  }

  .header h1 {
    margin: 0;
    font-size: 32px;
    font-weight: 800;
  }

  .header p {
    margin-top: 8px;
    opacity: 0.9;
    font-size: 14px;
  }

  .stats {
    display: flex;
    gap: 16px;
    padding: 24px 32px;
    background: #ffffff;
  }

  .stat-card {
    flex: 1;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 16px;
    padding: 20px;
    text-align: center;
  }

  .stat-value {
    font-size: 28px;
    font-weight: 800;
    color: #1e293b;
  }

  .stat-label {
    margin-top: 6px;
    font-size: 13px;
    color: #64748b;
  }

  .content {
    padding: 0 32px 32px 32px;
  }

  .section-title {
    font-size: 18px;
    font-weight: 700;
    margin-bottom: 16px;
    color: #1e293b;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    overflow: hidden;
    border-radius: 16px;
    border: 1px solid #e2e8f0;
  }

  thead {
    background: #1e293b;
    color: white;
  }

  th {
    padding: 14px;
    text-align: left;
    font-size: 14px;
    font-weight: 700;
  }

  td {
    padding: 14px;
    border-top: 1px solid #e2e8f0;
    font-size: 15px;
  }

  tbody tr:nth-child(even) {
    background: #f8fafc;
  }

  .footer {
    margin-top: 32px;
    text-align: center;
    font-size: 13px;
    color: #64748b;
    border-top: 1px solid #e2e8f0;
    padding-top: 20px;
  }

  @media (max-width: 600px) {
    body {
      padding: 12px;
    }

    .header,
    .content {
      padding: 20px;
    }

    .stats {
      flex-direction: column;
      padding: 20px;
    }

    .header h1 {
      font-size: 24px;
    }
  }
</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Grocery Order Summary</h1>
      <p>Generated on ${DateTime.now()}</p>
    </div>

    <div class="stats">
      <div class="stat-card">
        <div class="stat-value">${selectedItems.length}</div>
        <div class="stat-label">Items</div>
      </div>

      <div class="stat-card">
        <div class="stat-value">$totalQuantity</div>
        <div class="stat-label">Total Quantity</div>
      </div>
    </div>

    <div class="content">
      <div class="section-title">Selected Items</div>

      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Item Name</th>
            <th>Quantity</th>
          </tr>
        </thead>
        <tbody>
          $tableRows
        </tbody>
      </table>

      <div class="footer">
        Thank you for using Grocery App
      </div>
    </div>
  </div>
</body>
</html>
''';

  // Save HTML file
  final directory = await getApplicationDocumentsDirectory();
  final file = File(
    '${directory.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.html',
  );

  await file.writeAsString(html, flush: true);

  return file;
}