#include "Logging.as";
#include "KL_Common.as";

const float ELO_BASE = 5; // should be kept the same as in server ratings code
const float ELO_DIVISOR = 1400; // should be kept the same as in server ratings code
const float MAX_ODDS = 1000;
const float E = 2.71828;
const float[][] NORMAL_DISTRIBUTION_TABLE = {
    {-3.4, 0.0003}, {-3.3, 0.0005}, {-3.2, 0.0007}, {-3.1, 0.0010},
    {-3.0, 0.0013}, {-2.9, 0.0019}, {-2.8, 0.0026}, {-2.7, 0.0035},
    {-2.6, 0.0047}, {-2.5, 0.0062}, {-2.4, 0.0082}, {-2.3, 0.0107},
    {-2.2, 0.0139}, {-2.1, 0.0179}, {-2.0, 0.0228}, {-1.9, 0.0287},
    {-1.8, 0.0359}, {-1.7, 0.0446}, {-1.6, 0.0548}, {-1.5, 0.0668},
    {-1.4, 0.0808}, {-1.3, 0.0968}, {-1.2, 0.1151}, {-1.1, 0.1357},
    {-1.0, 0.1587}, {-0.9, 0.1841}, {-0.8, 0.2119}, {-0.7, 0.2420},
    {-0.6, 0.2743}, {-0.5, 0.3085}, {-0.4, 0.3446}, {-0.3, 0.3821},
    {-0.2, 0.4207}, {-0.1, 0.4602}, {0.0, 0.5000},  {0.0, 0.5000},
    {0.1, 0.5398},  {0.2, 0.5793},  {0.3, 0.6179},  {0.4, 0.6554},
    {0.5, 0.6915},  {0.6, 0.7257},  {0.7, 0.7580},  {0.8, 0.7881},
    {0.9, 0.8159},  {1.0, 0.8413},  {1.1, 0.8643},  {1.2, 0.8849},
    {1.3, 0.9032},  {1.4, 0.9192},  {1.5, 0.9332},  {1.6, 0.9452},
    {1.7, 0.9554},  {1.8, 0.9641},  {1.9, 0.9713},  {2.0, 0.9772},
    {2.1, 0.9821},  {2.2, 0.9861},  {2.3, 0.9893},  {2.4, 0.9918},
    {2.5, 0.9938},  {2.6, 0.9953},  {2.7, 0.9965},  {2.8, 0.9974},
    {2.9, 0.9981},  {3.0, 0.9987},  {3.1, 0.9990},  {3.2, 0.9993},
    {3.3, 0.9995},  {3.4, 0.9997}
};

// Returns the p(Z <= z) using the standard normal distribution (u=0, d=1)
float standardNormalDistributionLookup(float z) {
    for (uint i=0; i < NORMAL_DISTRIBUTION_TABLE.length; i++) {
        float[] pair = NORMAL_DISTRIBUTION_TABLE[i];
        if (z <= pair[0])
            return pair[1];
    }

    // Return the last value if unfound
    return NORMAL_DISTRIBUTION_TABLE[NORMAL_DISTRIBUTION_TABLE.length-1][1];
}

// Returns the probability that player 1 wins the match, given the current score
float getWinProbability(float p1Rating, float p2Rating, u8 p1Score, u8 p2Score, u8 duelToScore) {
    float delta = p2Rating - p1Rating;

    // represents the number of rounds player1 is likely to win
    float expectedScorePct = 1.0 / (1.0 + Maths::Pow(ELO_BASE, delta/ELO_DIVISOR));

    // how many games each player needs to win
    float p1NeedToWin = duelToScore - p1Score;
    float p2NeedToWin = duelToScore - p2Score;

    // normal distribution parameters
    float d = 1;
    float u = expectedScorePct - 0.5;

    float z = p2NeedToWin / (p1NeedToWin + p2NeedToWin) - 0.5;
    float result = standardNormalDistributionLookup(z) * d + u;
    return result;
}

// Returns the odds that should be assigned for the given win probability
// Odds are in the format 1:x and this function returns the x
float getOddsFromWinProbability(float winProb) {
    // TODO: this value 15 is just what worked when tweaking the numbers, but it really shouldn't
    // be hardcoded.
    float odds = 1 + MAX_ODDS / Maths::Pow(E, 15*winProb);

    // Safety check
    if (odds <= 1)
        return 1;
    else if (odds >= MAX_ODDS)
        return MAX_ODDS;
    else
        return odds;
}

void getWinPctAndOddsForMatch(RatedMatch match, float &out winP1, float &out winP2, float &out oddsP1, float &out oddsP2) {
    s16 p1Rating = getPlayerRating(match.player1, match.kagClass);
    s16 p2Rating = getPlayerRating(match.player2, match.kagClass);

    // If ratings couldn't be loaded assume the default
    if (p1Rating == -1) {
        p1Rating = 1000;
    }
    if (p2Rating == -1) {
        p2Rating = 1000;
    }

    winP1 = getWinProbability(p1Rating, p2Rating, match.player1Score,
                                    match.player2Score, match.duelToScore);
    winP2 = 1 - winP1;
    oddsP1 = getOddsFromWinProbability(winP1);
    oddsP2 = getOddsFromWinProbability(winP2);
}

void testBettingOddsExamples() {
    float[][] examples = {
        {1000, 1500, 0, 0, 5},
        {1100, 1500, 0, 0, 5},
        {1200, 1500, 0, 0, 5},
        {1200, 1500, 1, 0, 5},
        {1200, 1500, 2, 0, 5},
        {1200, 1500, 3, 0, 5},
        {1500, 1000, 0, 0, 5},
        {1500, 1100, 0, 0, 5},
        {1500, 1200, 0, 0, 5},
        {1500, 1200, 1, 0, 5},
        {1500, 1200, 2, 0, 5},
        {1000, 2000, 0, 0, 5}
    };

    for (uint i=0; i < examples.length; i++) {
        float[] example = examples[i];
        float p1Rating = example[0];
        float p2Rating = example[1];
        float p1Score = example[2];
        float p2Score = example[3];
        float duelToScore = example[4];

        float winP1 = getWinProbability(p1Rating, p2Rating, p1Score, p2Score, duelToScore);
        float winP2 = 1 - winP1;

        float oddsP1 = getOddsFromWinProbability(winP1);
        float oddsP2 = getOddsFromWinProbability(winP2);

        log("testBettingOddsExamples", "(winP1, winP2) - (oddsP1, oddsP2)"
                .replace("winP1", ''+winP1)
                .replace("winP2", ''+winP2)
                .replace("oddsP1", ''+oddsP1)
                .replace("oddsP2", ''+oddsP2)
                );
    }
}
