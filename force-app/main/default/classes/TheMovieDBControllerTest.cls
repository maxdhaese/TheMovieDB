/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class TheMovieDBControllerTest {

    /*
     * Mock voor succesvolle TMDB API response
     */
    private class TMDBSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                '"page":1,' +
                '"results":[' +
                    '{' +
                        '"id":12345,' +
                        '"title":"Inception",' +
                        '"overview":"A mind-bending thriller",' +
                        '"release_date":"2010-07-16",' +
                        '"poster_path":"/poster1.jpg",' +
                        '"backdrop_path":"/backdrop1.jpg"' +
                    '},' +
                    '{' +
                        '"id":67890,' +
                        '"title":"Interstellar",' +
                        '"overview":"A journey beyond the stars",' +
                        '"release_date":"2014-11-07",' +
                        '"poster_path":"/poster2.jpg",' +
                        '"backdrop_path":null' +
                    '}' +
                '],' +
                '"total_pages":1,' +
                '"total_results":2' +
            '}');
            return res;
        }
    }

    /*
     * Mock voor foutieve TMDB API response
     */
    private class TMDBErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_message":"Internal Server Error"}');
            return res;
        }
    }

    @IsTest
    static void testSearchMovies_BlankSearchTerm() {
        Test.startTest();
        List<TheMovieDBController.MovieSearchResult> results =
            TheMovieDBController.searchMovies('');
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size(), 'Blank search term should return empty list');
    }

    @IsTest
    static void testSearchMovies_Success() {
        Test.setMock(HttpCalloutMock.class, new TMDBSuccessMock());

        Test.startTest();
        List<TheMovieDBController.MovieSearchResult> results =
            TheMovieDBController.searchMovies('Inception');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 movies');

        TheMovieDBController.MovieSearchResult firstMovie = results[0];
        System.assertEquals('12345', firstMovie.movieId);
        System.assertEquals('Inception', firstMovie.title);
        System.assertEquals('A mind-bending thriller', firstMovie.overview);
        System.assertEquals(Date.newInstance(2010, 7, 16), firstMovie.releaseDate);
        System.assertEquals('https://image.tmdb.org/t/p/w500/poster1.jpg', firstMovie.posterUrl);
        System.assertEquals('https://image.tmdb.org/t/p/w500/backdrop1.jpg', firstMovie.image);

        TheMovieDBController.MovieSearchResult secondMovie = results[1];
        System.assertEquals('67890', secondMovie.movieId);
        System.assertEquals('Interstellar', secondMovie.title);
        System.assertEquals('https://image.tmdb.org/t/p/w500/poster2.jpg', secondMovie.posterUrl);
        System.assertEquals(
            'https://image.tmdb.org/t/p/w500/poster2.jpg',
            secondMovie.image,
            'If backdrop_path is null, image should fall back to posterUrl'
        );
    }

@IsTest
static void testSearchMovies_ErrorResponse() {
    Test.setMock(HttpCalloutMock.class, new TMDBErrorMock());

    Test.startTest();
    Boolean hasThrown = false;
    try {
        TheMovieDBController.searchMovies('Batman');
    } catch (AuraHandledException e) {
        hasThrown = true;
        System.assertNotEquals(null, e, 'Expected AuraHandledException');
    }
    Test.stopTest();

    System.assertEquals(true, hasThrown, 'Expected exception to be thrown');
}

@IsTest
static void testCreateImportedMovies_EmptyList() {
    Test.startTest();
    Boolean hasThrown = false;
    try {
        TheMovieDBController.createImportedMovies(
            new List<TheMovieDBController.MovieSearchResult>()
        );
    } catch (AuraHandledException e) {
        hasThrown = true;
        System.assertNotEquals(null, e, 'Expected AuraHandledException');
    }
    Test.stopTest();

    System.assertEquals(true, hasThrown, 'Expected exception for empty input');
}

@IsTest
static void testCreateImportedMovies_NullInput() {
    Test.startTest();
    Boolean hasThrown = false;
    try {
        TheMovieDBController.createImportedMovies(null);
    } catch (AuraHandledException e) {
        hasThrown = true;
        System.assertNotEquals(null, e, 'Expected AuraHandledException');
    }
    Test.stopTest();

    System.assertEquals(true, hasThrown, 'Expected exception for null input');
}
}