import React, { Component } from 'react';
import './MatchHistoryRow.css';
import CharacterPortrait from './CharacterPortrait.js';

class MatchHistoryRow extends Component {
    render() {
        let t = new Date();
        t.setTime(this.props.time * 1000);
        let dateString = t.toLocaleDateString();
        let timeString = t.toLocaleTimeString();
        return (
            <tr className="MatchHistoryRow">
                <td>{this.props.region}</td>
                <td>{this.props.kagClass}</td>
                <td className="row _match">
                    <div className="flex1">
                        <div className="row">
                            <div>
                                {this.props.player1}
                            </div>
                        </div>
                        <div className="row">
                            <div>
                            {this.props.player1Score}
                            </div>
                        </div>
                    </div>
                    <div className="_vs">
                        vs.
                    </div>
                    <div>
                        <div className="row">
                            <div>
                                {this.props.player2}
                            </div>
                        </div>
                        <div className="row">
                            <div>
                                {this.props.player2Score}
                            </div>
                        </div>
                    </div>
                </td>
                <td>{dateString}</td>
                <td>{timeString}</td>
            </tr>
        );
    }
}
export default MatchHistoryRow;
