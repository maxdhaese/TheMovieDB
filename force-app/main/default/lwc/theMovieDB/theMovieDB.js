import { LightningElement, track } from 'lwc';
import searchMovies from '@salesforce/apex/TheMovieDBController.searchMovies';
import createImportedMovies from '@salesforce/apex/TheMovieDBController.createImportedMovies';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MovieImporter extends LightningElement {
    @track movies = [];

    searchTerm = '';
    isLoading = false;
    hasSearched = false;

    get disableImportButton() {
        return !this.movies.some(movie => movie.selected);
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    async handleSearch() {
        if (!this.searchTerm || !this.searchTerm.trim()) {
            this.showToast('Fout', 'Geef eerst een zoekterm in.', 'error');
            return;
        }

        this.isLoading = true;
        this.hasSearched = true;

        try {
            const result = await searchMovies({ searchTerm: this.searchTerm });
            this.movies = result.map(movie => ({
                ...movie,
                selected: false
            }));
        } catch (error) {
            this.movies = [];
            this.showToast('Fout', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleMovieSelection(event) {
        const selectedMovieId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.movies = this.movies.map(movie => {
            if (movie.movieId === selectedMovieId) {
                return { ...movie, selected: isChecked };
            }
            return movie;
        });
    }

    async handleImport() {
        const selectedMovies = this.movies
            .filter(movie => movie.selected)
            .map(movie => ({
                movieId: movie.movieId,
                title: movie.title,
                overview: movie.overview,
                releaseDate: movie.releaseDate,
                posterUrl: movie.posterUrl,
                image: movie.image
            }));

        if (!selectedMovies.length) {
            this.showToast('Info', 'Selecteer minstens één film.', 'info');
            return;
        }

        this.isLoading = true;

        try {
            const insertedIds = await createImportedMovies({ selectedMovies });

            this.showToast(
                'Succes',
                `${insertedIds.length} film(s) succesvol geïmporteerd.`,
                'success'
            );

            this.movies = this.movies.map(movie => ({
                ...movie,
                selected: false
            }));
        } catch (error) {
            this.showToast('Fout', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || 'Onbekende fout';
    }
}