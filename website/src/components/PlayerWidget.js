import React from 'react';
import './PlayerWidget.css';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import * as utils from '../utils';
import CharacterPortrait from './CharacterPortrait';
import ClassIcon from './ClassIcon';
import {Link} from 'react-router-dom';

class PlayerWidget extends DynamicComponent {
    getEndpoints(props) {
        return {"player": endpoints.player(props.username)}
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return <div className="PlayerWidget">{this.getLoadingDynamicContent()}</div>;

        let playerData = this.getDynamicData("player");
        let ratings = [];
        for (let region of utils.getValidRegions()) {
            if (region in playerData.ratings)
                ratings.push(playerData.ratings[region]);
        }
        let [bestClass, bestRating] = this.getBestClassAndRating(ratings);

        let noClantag, noNickname;
        if (!playerData.clantag) {
            playerData.clantag = "CLAN";
            noClantag = true;
        }

        if (!playerData.nickname) {
            playerData.nickname = "nickname";
            noNickname = true;
        }

        return (
            <div className={"PlayerWidget " + (this.props.flipped ? " _flipped" : "")}>
                <Link to={"/player/"+this.props.username}>
                    <CharacterPortrait head={playerData.head} gender={playerData.gender} kagClass={bestClass}
                        username={this.props.username} />
                    <div className="_text">
                        <span className="_username">
                            {this.props.username}
                        </span>
                        <div>
                            <span className={"_clantag " + (noClantag ? "empty" : "")}>{playerData.clantag}</span>
                            <span className={"_nickname " + (noNickname ? "empty" : "")}>{playerData.nickname}</span>
                        </div>
                        <span className="_title">
                            <ClassIcon kagClass={bestClass} />
                            {utils.getTitleFromRating(bestRating)} {bestClass}
                        </span>
                    </div>
                </Link>
            </div>
        );
    }

    getBestClassAndRating(ratings) {
        let bestClass = "knight";
        let bestRating = -1;

        for (let ratData of ratings) {
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

        return [bestClass, bestRating];
    }
}
export default PlayerWidget;
