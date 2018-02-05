import React from 'react';
import './MatchPage.css';
import Page from './Page';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import PlayerWidget from '../components/PlayerWidget';
import FlagIcon from '../components/FlagIcon';
import * as utils from '../utils';

/*
<span className="_username">
    <PlayerWidget username={username} onlyPortrait={true} />
</span>
*/

let SummaryLine = ({winnerOrLoser, username, score, ratingChange, color}) => {
    return (
        <div className={"_SummaryLine " + color}>
            <div className="_colorBlock"></div>
            <span className="_status">{winnerOrLoser}</span>
            <span className="_username">{username}</span>
            <span className="_score">{score}</span>
            <span className="_ratingChange">{utils.formatRatingChange(ratingChange)}</span>
        </div>
    );
};

class MatchPage extends DynamicComponent {
    getEndpoints(props) {
        return {"match": endpoints.match(props.match.params.matchID)}
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return this.getLoadingDynamicContent();
        else  {
            let match = this.getDynamicData("match");
            let [dateString, timeString] = utils.unixTimeToDateAndTime(match.match_time);
            let rounds = match.player1_score + match.player2_score;

            let roundInfoBoxes = [];
            for (let i = 0, len = rounds; i < len; i++) {
                roundInfoBoxes.push(
                    <div key={i} className="box">
                        <div className="_box_label">
                            Round {i+1}
                        </div>
                        Coming soon!
                    </div>
                    );
            }

            let winner, loser, winnerScore, loserScore, winnerRatingChange, loserRatingChange, winnerColor, loserColor;
            if (match.player1_score > match.player2_score) {
                winner = match.player1;
                loser = match.player2;
                winnerScore = match.player1_score;
                loserScore  = match.player2_score;
                winnerRatingChange = match.player1_rating_change;
                loserRatingChange = match.player2_rating_change;
                winnerColor = "blue";
                loserColor = "red";
            }
            else {
                winner = match.player2;
                loser = match.player1;
                winnerScore = match.player2_score;
                loserScore  = match.player1_score;
                winnerRatingChange = match.player2_rating_change;
                loserRatingChange = match.player1_rating_change;
                winnerColor = "red";
                loserColor = "blue";
            }

            return (
                <div className="MatchPage">
                    <Page title="Match Details">
                        <div className="_vsRow box">
                            <div className="_blueBlock"></div>
                            <PlayerWidget username={match.player1} />
                            <div className="_vs">vs.</div>
                            <PlayerWidget username={match.player2} flipped={true} />
                            <div className="_redBlock"></div>
                        </div>
                        <div className="_infoRow box">
                            <div>
                                Region: {match.region}
                                <FlagIcon region={match.region} />
                            </div>
                            <div>Time: <span className="_time">{dateString} {timeString}</span></div>
                            <div>Match ID: <span className="_id">{match.id}</span></div>
                        </div>
                        {roundInfoBoxes}
                        <div className="_summaryRow box">
                            <div className="_box_label">
                                Summary
                            </div>
                            <SummaryLine winnerOrLoser="Winner" username={winner} score={winnerScore}
                                ratingChange={winnerRatingChange} color={winnerColor} />
                            <SummaryLine winnerOrLoser="Loser" username={loser} score={loserScore}
                                ratingChange={loserRatingChange} color={loserColor} />
                        </div>
                    </Page>
                </div>
                );
        }
    }
}

export default MatchPage;
