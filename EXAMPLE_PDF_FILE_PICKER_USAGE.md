# PDF File Picker Usage Example

## New Methods Available

The `PDFService` now provides file picker functionality to let users choose where to save their PDF reports.

### 📄 **Single PDF with File Picker**
```dart
// Generate PDF and let user choose save location
final savedPath = await PDFService.generateAndSavePDFWithPicker(
  imagePath: '/path/to/image.jpg',
  apiResponse: damageAnalysisResponse,
  suggestedFileName: 'my_damage_report_2025-09-07.pdf', // Optional
);

if (savedPath != null) {
  print('PDF saved to: $savedPath');
  // Show success message to user
} else {
  print('PDF save cancelled or failed');
}
```

### 📄 **Multiple PDFs with File Picker**
```dart
// Generate multi-image PDF and let user choose save location
final savedPath = await PDFService.generateAndSaveMultiplePDFWithPicker(
  imagePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
  apiResponses: {
    '/path/to/image1.jpg': response1,
    '/path/to/image2.jpg': response2,
  },
  suggestedFileName: 'multi_damage_report_2025-09-07.pdf', // Optional
);
```

## 🎯 **Integration Example**

Here's how you might integrate this into your existing code:

```dart
class DamageAnalysisScreen extends StatefulWidget {
  // ... existing code
  
  Future<void> _savePDFReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      // Generate PDF with file picker
      final savedPath = await PDFService.generateAndSavePDFWithPicker(
        imagePath: widget.imagePath,
        apiResponse: widget.apiResponse,
        suggestedFileName: 'damage_assessment_${DateTime.now().toString().split(' ')[0]}.pdf',
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (savedPath != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Option to open file manager or share file
                print('Open file: $savedPath');
              },
            ),
          ),
        );
      } else {
        // User cancelled or save failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF save cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## 🔄 **Fallback Behavior**

If the file picker fails or user cancels:
- The system automatically falls back to the original save method
- PDF will be saved to the default InsureVis/documents folder
- User gets appropriate feedback about the save location

## 🎨 **UI Integration**

Add a save button to your results screen:
```dart
ElevatedButton.icon(
  onPressed: _savePDFReport,
  icon: Icon(Icons.save_alt),
  label: Text('Save PDF Report'),
  style: ElevatedButton.styleFrom(
    backgroundColor: GlobalStyles.primaryColor,
  ),
)
```

## 📱 **User Experience**

Users will see:
1. **File picker dialog** with suggested filename
2. **Folder navigation** to choose save location
3. **Success/failure feedback** via SnackBar
4. **Automatic fallback** if picker fails

This gives users full control over where their important damage assessment reports are saved!
