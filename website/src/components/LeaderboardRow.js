import React, { Component } from 'react';
import './LeaderboardRow.css';
import WinRatio from './WinRatio';
import CharacterPortrait from './CharacterPortrait.js';
import {Link} from 'react-router-dom';

class LeaderboardRow extends Component {
    render() {
        return (
            <tr className="LeaderboardRow">
                <td>{this.props.rank}</td>
                <td className="LeaderboardRow-name">
                    <Link to={"/player/"+this.props.name}>
                        <CharacterPortrait head={this.props.head} gender={this.props.gender} kagClass={this.props.kagClass}
                            username={this.props.name} />
                        <span>{this.props.name}</span>
                    </Link>
                </td>
                <td><WinRatio wins={this.props.wins} losses={this.props.losses} /></td>
                <td>{this.props.rating}</td>
            </tr>
        );
    }
}
export default LeaderboardRow;
