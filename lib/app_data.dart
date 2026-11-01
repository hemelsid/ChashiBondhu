import 'core/remote/remote_data.dart';
import 'features/briefing/briefing.dart';
import 'features/contacts/contacts_data.dart';
import 'features/disease/common/disease_library.dart';
import 'features/market/market_price_repository.dart';

/// Tells [RemoteData] how to check each downloaded file before using it.
/// A file that fails its check is ignored; the app keeps the last good copy.
void registerRemoteData() {
  RemoteData.registerValidator('contacts.json', ContactsData.isValid);
  RemoteData.registerValidator('market_prices.json', GithubMarketPriceSource.isValid);
  RemoteData.registerValidator(Briefing.file, Briefing.isValid);
  RemoteData.registerValidator(
      DiseaseLibrary.fileOf(DiseaseKind.fish), (t) => DiseaseLibrary.isSafe(DiseaseKind.fish, t));
  RemoteData.registerValidator(
      DiseaseLibrary.fileOf(DiseaseKind.crop), (t) => DiseaseLibrary.isSafe(DiseaseKind.crop, t));
}
