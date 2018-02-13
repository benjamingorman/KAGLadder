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

        let noClantag, noNickname;
        if (!playerData.clantag) {
            playerData.clantag = "CLAN";
            noClantag = true;
        }

        if (!playerData.nickname) {
            playerData.nickname = "nickname";
            noNickname = true;
        }

        let displayedKagClass;
        let displayedTitle;
        if (this.props.forcedKagClass) {
            displayedKagClass = this.props.forcedKagClass;
            displayedTitle = utils.getTitleFromRating(this.getBestRatingForClass(playerData.ratings, displayedKagClass));
        }
        else {
            let [bestClass, bestRating] = this.getBestClassAndRating(playerData.ratings);
            displayedKagClass = bestClass;
            displayedTitle = utils.getTitleFromRating(bestRating);
        }

        return (
            <div className={"PlayerWidget " + (this.props.flipped ? " _flipped" : "")}>
                <Link to={"/player/"+this.props.username}>
                    <CharacterPortrait head={playerData.head} gender={playerData.gender}
                        kagClass={displayedKagClass} username={this.props.username} />
                    <div className="_text">
                        <span className="_username">
                            {this.props.username}
                        </span>
                        <div>
                            <span className={"_clantag " + (noClantag ? "empty" : "")}>{playerData.clantag}</span>
                            <span className={"_nickname " + (noNickname ? "empty" : "")}>{playerData.nickname}</span>
                        </div>
                        <span className="_title">
                            <ClassIcon kagClass={displayedKagClass} />
                            {displayedTitle} {displayedKagClass}
                        </span>
                    </div>
                </Link>
            </div>
        );
    }

    getBestRatingForClass(ratings, whichClass) {
        let bestRating = -1;

        for (let region in ratings) {
            for (let kagClass in ratings[region]) {
                if (kagClass === whichClass) {
                    let rat = ratings[region][kagClass].rating;
                    if (rat > bestRating) {
                        bestRating = rat;
                    }
                }
            }
        }

        return bestRating;
    }

    getBestClassAndRating(ratings) {
        let bestClass = "knight";
        let bestRating = -1;

        for (let region in ratings) {
            for (let kagClass in ratings[region]) {
                let rat = ratings[region][kagClass].rating;
                if (rat > bestRating) {
                    bestClass = kagClass;
                    bestRating = rat;
                }
            }
        }

        return [bestClass, bestRating];
    }
}
export default PlayerWidget;
