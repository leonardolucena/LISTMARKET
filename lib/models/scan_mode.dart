enum ScanMode {
  barcode,
  shelfLabel,
}

extension ScanModeLabels on ScanMode {
  String get label {
    switch (this) {
      case ScanMode.barcode:
        return 'Código de Barras';
      case ScanMode.shelfLabel:
        return 'Preço da Gôndola';
    }
  }

  String get hint {
    switch (this) {
      case ScanMode.barcode:
        return 'Aponte para o código de barras';
      case ScanMode.shelfLabel:
        return 'Enquadre só a etiqueta dentro do retângulo';
    }
  }

  ({double width, double height}) get guideSize {
    switch (this) {
      case ScanMode.barcode:
        return (width: 256, height: 128);
      case ScanMode.shelfLabel:
        return (width: 300, height: 180);
    }
  }
}
