import '../services/mock_data.dart';

double getEmissionFactor(String iconId) {
  if (iconId == IconIds.train) return 0.06;
  if (iconId == IconIds.bus) return 0.10;
  if (iconId == IconIds.car) return 0.27;
  return 0.0;
}

double calculateEmission(double distance, String iconId) {
  return distance * getEmissionFactor(iconId);
}
