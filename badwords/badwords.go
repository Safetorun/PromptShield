package badwords

import (
	"github.com/safetorun/PromptDefender/embeddings"
)

type ClosestMatchScore struct {
	MatchDescription string
	Score            float64
}

type ClosestMatcher interface {
	GetClosestMatch(string) (ClosestMatchScore, error)
}

type BadWords struct {
	matcher   ClosestMatcher
	threshold float64
}

func New(matcher ClosestMatcher) *BadWords {
	return &BadWords{matcher: matcher}
}

func (badWords BadWords) CheckPromptContainsBadWords(prompt string) (*bool, error) {
	score, err := badWords.matcher.GetClosestMatch(prompt)

	if err != nil {
		return nil, err
	}

	containsBadWord := score.Score > badWords.threshold
	return &containsBadWord, nil

}

func (badWords BadWords) RetrieveBadwordEmbeddings() (*[]embeddings.EmbeddingValue, error) {
	embeddings := make([]embeddings.EmbeddingValue, 0)
	return &embeddings, nil
}
