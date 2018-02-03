import React, { Component } from 'react';
import './MatchHistoryRow.css';
//import CharacterPortrait from './CharacterPortrait.js';
import ClassIcon from './ClassIcon.js';

class MatchHistoryRow extends Component {
    render() {
        let t = new Date();
        t.setTime(this.props.time * 1000);
        let dateString = t.toLocaleDateString();
        let timeString = t.toLocaleTimeString();

        let winningPlayer = 2;
        if (this.props.player1Score > this.props.player2Score)
            winningPlayer = 1;

        return (
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
        );
    }
}
export default MatchHistoryRow;
