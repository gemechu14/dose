enum DeveloperRatio { oneToOne, oneToOnePointFive, oneToTwo, manual }

double? ratioMultiplier(DeveloperRatio ratio) {
  switch (ratio) {
    case DeveloperRatio.oneToOne:
      return 1.0;
    case DeveloperRatio.oneToOnePointFive:
      return 1.5;
    case DeveloperRatio.oneToTwo:
      return 2.0;
    case DeveloperRatio.manual:
      return null;
  }
}

String ratioLabel(DeveloperRatio ratio) {
  switch (ratio) {
    case DeveloperRatio.oneToOne:
      return '1:1';
    case DeveloperRatio.oneToOnePointFive:
      return '1:1.5';
    case DeveloperRatio.oneToTwo:
      return '1:2';
    case DeveloperRatio.manual:
      return 'manual';
  }
}

DeveloperRatio ratioFromLabel(String? value) {
  switch (value) {
    case '1:1':
      return DeveloperRatio.oneToOne;
    case '1:1.5':
      return DeveloperRatio.oneToOnePointFive;
    case '1:2':
      return DeveloperRatio.oneToTwo;
    case 'manual':
      return DeveloperRatio.manual;
    default:
      return DeveloperRatio.oneToOne;
  }
}

/// Pigment-side share of total bowl waste (COLOR + TONER + treatment).
double wastePigmentShare(DeveloperRatio ratio) {
  switch (ratio) {
    case DeveloperRatio.oneToOne:
      return 0.5;
    case DeveloperRatio.oneToOnePointFive:
      return 0.4;
    case DeveloperRatio.oneToTwo:
      return 1 / 3;
    case DeveloperRatio.manual:
      return 0;
  }
}

/// Developer-side share of total bowl waste.
double wasteDeveloperShare(DeveloperRatio ratio) {
  switch (ratio) {
    case DeveloperRatio.oneToOne:
      return 0.5;
    case DeveloperRatio.oneToOnePointFive:
      return 0.6;
    case DeveloperRatio.oneToTwo:
      return 2 / 3;
    case DeveloperRatio.manual:
      return 0;
  }
}

/// Preview split for mix-more dialog.
({double pigmentWaste, double developerWaste}) splitBowlWaste(
  double totalWaste,
  DeveloperRatio ratio,
) {
  if (ratio == DeveloperRatio.manual || totalWaste <= 0) {
    return (pigmentWaste: 0, developerWaste: 0);
  }
  return (
    pigmentWaste: totalWaste * wastePigmentShare(ratio),
    developerWaste: totalWaste * wasteDeveloperShare(ratio),
  );
}
