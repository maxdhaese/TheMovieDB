public with sharing class TheMovieDBController {

    private static final String TMDB_BASE_URL = 'https://api.themoviedb.org/3';
    private static final String TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p/w500';

    // Tijdelijk voor je case
    private static final String TMDB_BEARER_TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2ZTMzNzQwYzI4NmMxZjllZjU0ZGE0YWUyMWMyOWVmNiIsIm5iZiI6MTczMDc5MTkyNC4wNzgsInN1YiI6IjY3MjljOWY0ZDBjMDcyYWQ0OGY1MTgwMiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.Vyj_1ChfFJXluqbJOmP9Igv_UODZixRSefaHrM4wDUU';

    public class MovieSearchResult {
        @AuraEnabled public String movieId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String overview { get; set; }
        @AuraEnabled public Date releaseDate { get; set; }
        @AuraEnabled public String posterUrl { get; set; }
        @AuraEnabled public String image { get; set; }
    }

    public class TMDBSearchResponse {
        public Integer page;
        public List<TMDBMovie> results;
        public Integer total_pages;
        public Integer total_results;
    }

    public class TMDBMovie {
        public Integer id;
        public String title;
        public String overview;
        public String release_date;
        public String poster_path;
        public String backdrop_path;
    }

    @AuraEnabled(cacheable=true)
    public static List<MovieSearchResult> searchMovies(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<MovieSearchResult>();
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(
            TMDB_BASE_URL +
            '/search/movie?query=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8') +
            '&include_adult=false&language=en-US&page=1'
        );
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TMDB_BEARER_TOKEN);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'TMDB zoekopdracht mislukt. HTTP status: ' + res.getStatusCode()
            );
        }

        TMDBSearchResponse apiResponse =
            (TMDBSearchResponse) JSON.deserialize(res.getBody(), TMDBSearchResponse.class);

        List<MovieSearchResult> output = new List<MovieSearchResult>();

        if (apiResponse != null && apiResponse.results != null) {
            for (TMDBMovie movie : apiResponse.results) {
                MovieSearchResult dto = new MovieSearchResult();
                dto.movieId = movie.id != null ? String.valueOf(movie.id) : null;
                dto.title = movie.title;
                dto.overview = movie.overview;

                if (!String.isBlank(movie.release_date)) {
                    try {
                        dto.releaseDate = Date.valueOf(movie.release_date);
                    } catch (Exception e) {
                        dto.releaseDate = null;
                    }
                }

                dto.posterUrl = !String.isBlank(movie.poster_path)
                    ? TMDB_IMAGE_BASE_URL + movie.poster_path
                    : null;

                dto.image = !String.isBlank(movie.backdrop_path)
                    ? TMDB_IMAGE_BASE_URL + movie.backdrop_path
                    : dto.posterUrl;

                output.add(dto);
            }
        }

        return output;
    }


    @AuraEnabled
    public static List<Id> createImportedMovies(List<MovieSearchResult> selectedMovies) {
        if (selectedMovies == null || selectedMovies.isEmpty()) {
            throw new AuraHandledException('Selecteer minstens één film.');
        }

        List<Movie__c> moviesToInsert = new List<Movie__c>();

        for (MovieSearchResult movie : selectedMovies) {
            Movie__c newMovie = new Movie__c();
            newMovie.Name = movie.title;
            newMovie.MovieId__c = movie.movieId;
            newMovie.Title__c = movie.title;
            newMovie.Overview__c = movie.overview;
            newMovie.Release_date__c = movie.releaseDate;
            newMovie.PosterURL__c = movie.posterUrl;
            newMovie.Image__c = movie.image;

            moviesToInsert.add(newMovie);
        }

        insert moviesToInsert;

        List<Id> insertedIds = new List<Id>();
        for (Movie__c movie : moviesToInsert) {
            insertedIds.add(movie.Id);
        }

        return insertedIds;
    }
}