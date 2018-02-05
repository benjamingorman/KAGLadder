import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import './MatchHistoryRow.css';
//import CharacterPortrait from './CharacterPortrait.js';
import ClassIcon from './ClassIcon.js';
import * as utils from '../utils';

class MatchHistoryRow extends Component {
    render() {
        let [dateString, timeString] = utils.unixTimeToDateAndTime(this.props.time);

        let winningPlayer = 2;
        if (this.props.player1Score > this.props.player2Score)
            winningPlayer = 1;

        return (
            <Link to={"/match/" + this.props.id}>
                <div className="MatchHistoryRow">
                    <div className="_region">{this.props.region}</div>
                    <div className="_kagClass"><ClassIcon kagClass={this.props.kagClass}/></div>
                    <div className={"_player _p1 " + (winningPlayer === 1 ? "_winner" : "")} >
                        {this.props.player1}<br/>
                        {this.props.player1Score}
                    </div>
                    <div className="_vs">vs.</div>
                    <div className={"_player _p2 " + (winningPlayer === 2 ? "_winner" : "")} >
                        {this.props.player2}<br/>
                        {this.props.player2Score}
                    </div>
                    <div className="_time">{dateString}<br/>{timeString}</div>
                </div>
            </Link>
        );
    }
}
export default MatchHistoryRow;
