import React, { Component } from 'react';
import './LeaderboardRow.css';
import WinRatio from './WinRatio';
import CharacterPortrait from './CharacterPortrait.js';
import { Link, withRouter } from 'react-router-dom';

class LeaderboardRow extends Component {
    render() {
        return (
            <tr className="LeaderboardRow" onClick={this.handleClick.bind(this, this.props.name)}>
                <td className="_rank">{this.props.rank}</td>
                <td className="LeaderboardRow-name">
                    <CharacterPortrait head={this.props.head} gender={this.props.gender} kagClass={this.props.kagClass}
                        username={this.props.name} />
                    <span>{this.props.name}</span>
                </td>
                <td><WinRatio wins={this.props.wins} losses={this.props.losses} /></td>
                <td>{this.props.rating}</td>
            </tr>
        );
    }

    handleClick(username) {
        console.log("handleClick", username);
        this.props.history.push('/player/'+username);
    }
}
LeaderboardRow = withRouter(LeaderboardRow);
export default LeaderboardRow;
