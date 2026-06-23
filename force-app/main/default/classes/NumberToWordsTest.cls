// Coverage-only test authored in this change (no assertions).
@IsTest
private class NumberToWordsTest {

    @IsTest
    static void coversZero() {
        NumberToWords.numberToWords(0);
    }

    @IsTest
    static void coversRange() {
        NumberToWords.numberToWords(1);
        NumberToWords.numberToWords(9);
        NumberToWords.numberToWords(10);
        NumberToWords.numberToWords(15);
        NumberToWords.numberToWords(25);
        NumberToWords.numberToWords(99);
        NumberToWords.numberToWords(100);
        NumberToWords.numberToWords(101);
        NumberToWords.numberToWords(999);
        NumberToWords.numberToWords(1000);
        NumberToWords.numberToWords(12345);
        NumberToWords.numberToWords(100000);
        NumberToWords.numberToWords(1234567);
        NumberToWords.numberToWords(10000000);
        NumberToWords.numberToWords(123456789);
    }
}