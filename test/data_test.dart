import 'dart:io';

import 'package:chashibondhu/core/data/bd_districts.dart';
import 'package:chashibondhu/core/domain/fish_species.dart';
import 'package:chashibondhu/features/briefing/briefing.dart';
import 'package:chashibondhu/features/briefing/farm_calendar.dart';
import 'package:chashibondhu/features/contacts/contacts_data.dart';
import 'package:chashibondhu/features/disease/common/disease_library.dart';
import 'package:chashibondhu/features/feed/feed_calculator.dart';
import 'package:chashibondhu/features/market/market_price_repository.dart';
import 'package:chashibondhu/features/pond/data/pond.dart';
import 'package:chashibondhu/features/reminders/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

String _data(String f) => File('assets/data/$f').readAsStringSync();

void main() {
  group('Online data files (assets/data) pass the same checks the app uses', () {
    test('contacts', () {
      final text = _data('contacts.json');
      expect(ContactsData.isValid(text), isTrue);
      final d = ContactsData.parse(text);
      expect(d.helplines.map((h) => h.phone), containsAll(['16123', '333', '1090', '999']));
      for (final o in d.officers) {
        expect(districtById(o.contact.districtId), isNotNull, reason: o.contact.name);
        expect(['fisheries', 'dae', 'dls'], contains(o.office));
      }
      for (final o in d.organizations) {
        expect(o.website.startsWith('https://'), isTrue, reason: o.name);
      }
    });

    test('market prices', () {
      expect(GithubMarketPriceSource.isValid(_data('market_prices.json')), isTrue);
    });

    test('briefing', () {
      expect(Briefing.isValid(_data('briefing.json')), isTrue);
    });

    test('disease libraries are safe', () {
      expect(DiseaseLibrary.isSafe(DiseaseKind.fish, _data('fish_diseases.json')), isTrue);
      expect(DiseaseLibrary.isSafe(DiseaseKind.crop, _data('crop_diseases.json')), isTrue);
    });

    test('a downloaded library with a dose is rejected', () {
      final bad = _data('fish_diseases.json').replaceFirst('চুন দিন', '৫ mg ওষুধ দিন');
      expect(DiseaseLibrary.isSafe(DiseaseKind.fish, bad), isFalse);
      expect(DiseaseLibrary.isSafe(DiseaseKind.fish, '{"broken":'), isFalse);
    });

    test('bad contacts file is rejected', () {
      expect(ContactsData.isValid('{"helplines": []}'), isFalse);
      expect(ContactsData.isValid('{"helplines": [{"name": "x", "number": "abc"}]}'), isFalse);
    });
  });

  group('Briefing', () {
    test('headlines parse, non-https links dropped', () {
      final b = Briefing.parse('''{"updated": "2026-11-02T03:00:00+00:00", "items": [
        {"title": "ধানের দাম বাড়ছে", "source": "খবর", "url": "https://example.com/a", "published": "2026-11-02T01:00:00+00:00", "topic": "বাজার"},
        {"title": "খারাপ লিংক", "url": "http://x"}
      ]}''');
      expect(b.items.length, 1);
      expect(b.items.first.topic, 'বাজার');
      expect(b.updated, isNotNull);
    });

    test('time ago in Bangla', () {
      final now = DateTime(2026, 11, 2, 12);
      expect(bnAgo(DateTime(2026, 11, 2, 9), now: now), '৩ ঘণ্টা আগে');
      expect(bnAgo(DateTime(2026, 10, 31, 12), now: now), '২ দিন আগে');
    });

    test('farm calendar has tips for every month', () {
      for (var m = 1; m <= 12; m++) {
        final t = FarmCalendar.forMonth(m);
        expect(t.fish, isNotEmpty);
        expect(t.crop, isNotEmpty);
      }
      expect(FarmCalendar.forMonth(11).name, contains('নভেম্বর'));
    });
  });

  group('District office websites', () {
    test('portal spelling', () {
      expect(DistrictOffices.website('fisheries', 'mymensingh'),
          'https://fisheries.mymensingh.gov.bd');
      expect(DistrictOffices.website('dae', 'jashore'), 'https://dae.jessore.gov.bd');
      expect(DistrictOffices.website('dls', 'bogura'), 'https://dls.bogra.gov.bd');
    });
  });

  group('More fish', () {
    test('6 common first, then more, "অন্য মাছ" last', () {
      expect(FishSpecies.main.length, 6);
      expect(FishSpecies.more.last, FishSpecies.other);
      expect(FishSpecies.values.length, greaterThanOrEqualTo(18));
    });

    test('every species has a harvest estimate or the default', () {
      for (final s in FishSpecies.values) {
        expect(estimateHarvest(s, DateTime(2026, 1, 1), now: DateTime(2026, 1, 2)).year,
            greaterThanOrEqualTo(2026));
      }
    });

    test('carps eat a little less', () {
      expect(FeedCalculator.ratePercent(FishSpecies.silverCarp, 100),
          lessThan(FeedCalculator.ratePercent(FishSpecies.shing, 100)));
    });

    test('typed name for "অন্য মাছ"', () {
      final p = Pond(
        id: 'p',
        name: 'পুকুর',
        areaShotok: 10,
        species: FishSpecies.other,
        customSpecies: 'টেংরা',
        stockCount: 100,
        stockDate: DateTime(2026, 1, 1),
        avgWeightG: 20,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(p.speciesLabel, 'টেংরা');
      expect(Pond.fromMap(p.toMap()).speciesLabel, 'টেংরা');
      expect(p.copyWith(species: FishSpecies.rui).speciesLabel, 'রুই');
    });
  });
}
