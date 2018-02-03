import React from 'react';
import './PlayerProfile.css';
import DynamicComponent from '../DynamicComponent';
import CharacterPortrait from './CharacterPortrait';
import endpoints from '../endpoints';
import MatchHistoryRow from './MatchHistoryRow';
import ClassIcon from './ClassIcon';
import PlayerRatingsBox from './PlayerRatingsBox';
import * as utils from '../utils';

class PlayerProfile extends DynamicComponent {
    getEndpoints(props) {
        return {"player": endpoints.players(props.username),
                "matchHistory": endpoints.playerMatchHistory(props.username),
                "ratingsEU": endpoints.playerRatings(props.username, "EU"),
                "ratingsUS": endpoints.playerRatings(props.username, "US"),
                "ratingsAUS": endpoints.playerRatings(props.username, "AUS"),
        };
    }

    render() {
        if (!(this.isAllDynamicDataLoaded())) {
            return this.getFailedDynamicContent();
        }
        else {
            let playerData = this.state.dynamicData.player;
            let matchHistoryData = this.state.dynamicData.matchHistory;
            let ratingsEU = this.getDynamicData("ratingsEU");
            let ratingsUS = this.getDynamicData("ratingsUS");
            let ratingsAUS = this.getDynamicData("ratingsAUS");
            let [bestClass, bestRating] = this.getBestClassAndRating();

            let matchHistoryRows = [];
            for (let i=0; i < matchHistoryData.length; ++i) {
                let entry = matchHistoryData[i];
                matchHistoryRows.push(<MatchHistoryRow key={i} region={entry.region} player1={entry.player1} player2={entry.player2} 
                                       kagClass={entry.kag_class} time={entry.match_time} player1Score={entry.player1_score}
                                       player2Score={entry.player2_score}/>);
            }

            return (
                <div className="PlayerProfile">
                    <div className="_col1">
                        <div className="_playerInfo">
                            <CharacterPortrait head={playerData.head} gender={playerData.gender} kagClass={bestClass} />
                            <div className="_text">
                                <span className="_username">
                                    {this.props.username}
                                </span>
                                <br/>
                                <span className="_nickname">
                                    {playerData.nickname}
                                </span>
                                <br/>
                                <span className="_title">
                                    <ClassIcon kagClass={bestClass} />
                                    {utils.getTitleFromRating(bestRating)} {bestClass}
                                </span>
                            </div>
                        </div>
                        <div className="box">
                            <div className="_box_label">
                                Match History
                            </div>
                            {matchHistoryRows.length} games played
                        </div>
                        <div className="_matchHistory">
                            {matchHistoryRows}
                        </div>
                    </div>
                    <div className="_col2">
                        <PlayerRatingsBox ratings={{EU: ratingsEU, US: ratingsUS, AUS: ratingsAUS}}/>
                        <div className="box">
                            <div className="_box_label">Rating graph</div>
                            Coming soon!
                        </div>
                        <div className="box">
                            <div className="_box_label">Activity</div>
                            Coming soon!
                        </div>
                        <div className="box">
                            <div className="_box_label">Stats</div>
                            Coming soon!
                        </div>
                    </div>
                </div>
            );
        }
    }

    getBestClassAndRating() {
        let bestClass = "knight";
        let bestRating = -1;

        for (let ratData of [this.getDynamicData("ratingsEU"), this.getDynamicData("ratingsUS"),
                             this.getDynamicData("ratingsAUS")]) {
            if (ratData) {
                for (let kag_class of utils.getValidKagClasses()) {
                    if (!ratData[kag_class])
                        continue;

                    let rat = ratData[kag_class].rating;
                    if (rat > bestRating) {
                        bestClass = kag_class;
                        bestRating = rat;
                    }
                }
            }
        }

        return [bestClass, bestRating];
    }
}
export default PlayerProfile;
