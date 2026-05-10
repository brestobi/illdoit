import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../repositories/user_repository_impl.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(ref);
});

class InvoiceService {
  final Ref _ref;

  InvoiceService(this._ref);

  Future<void> generateAndDownloadInvoice(Order order) async {
    final buyer = await _ref.read(userRepositoryProvider).getUserById(userId: order.buyerId);
    final seller = await _ref.read(userRepositoryProvider).getUserById(userId: order.sellerId);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('I\'ll Do It', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('South Africa'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(buyer.displayName),
                      pw.Text(buyer.email ?? ''),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FROM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(seller.displayName),
                      pw.Text(seller.email ?? ''),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Service: ${order.id}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('1')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('R${order.amount.toStringAsFixed(2)}')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('R${order.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.yellow700)),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Text('Thank you for using I\'ll Do It!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              pw.Text('Invoice Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
              pw.Text('Reference: ${order.id}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
