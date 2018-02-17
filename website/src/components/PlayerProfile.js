import React from 'react';
import './PlayerProfile.css';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import MatchHistoryRow from './MatchHistoryRow';
import PlayerRatingsBox from './PlayerRatingsBox';
import PlayerCoinsBox from './PlayerCoinsBox';
import PlayerStatsBox from './PlayerStatsBox';
import PlayerWidget from './PlayerWidget';
import PlayerRatingsGraph from './PlayerRatingsGraph';
//import * as utils from '../utils';

class PlayerProfile extends DynamicComponent {
    getEndpoints(props) {
        return {"player": endpoints.player(props.username),
                "matchHistory": endpoints.playerMatchHistory(props.username),
            };
    }

    render() {
        if (!(this.isAllDynamicDataLoaded()) || this.getDynamicData("player") === "null") {
            return this.getLoadingDynamicContent();
        }
        else {
            let playerData = this.state.dynamicData.player;
            let matchHistoryData = this.state.dynamicData.matchHistory;
            let ratingsEU = playerData["ratings"]["EU"];
            let ratingsUS = playerData["ratings"]["US"];
            let ratingsAUS = playerData["ratings"]["AUS"];

            let matchHistoryRows = [];
            for (let i=0; i < matchHistoryData.length; ++i) {
                let entry = matchHistoryData[i];
                matchHistoryRows.push(<MatchHistoryRow key={i} id={entry.id} region={entry.region} player1={entry.player1} player2={entry.player2} 
                                       kagClass={entry.kag_class} time={entry.match_time} player1Score={entry.player1_score}
                                       player2Score={entry.player2_score}/>);
            }

            return (
                <div className="PlayerProfile">
                    <div className="_col1">
                        <PlayerWidget username={this.props.username} />
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
                        <PlayerRatingsGraph username={this.props.username} matches={matchHistoryData} />
                        <PlayerCoinsBox coins={this.props.coins} />

                        <div className="box">
                            <div className="_box_label">Activity</div>
                            Coming soon!
                        </div>
                        <PlayerStatsBox />
                    </div>
                </div>
                );
        }
    }

    /*
    getFailedDynamicContent() {
        return "Couldn't load player: " + this.props.username;
    }
    */

}
export default PlayerProfile;
