import React, { Component } from 'react';
import './WinRatio.css';

function formatPercent(x) {
    return Math.floor(x * 100) + '%';
}

class WinRatio extends Component {
    render() {
        let winPercent = formatPercent(this.props.wins / (this.props.wins + this.props.losses));
        return (
            <div className="WinRatio">
                <div className="WinRatio-bar">
                    <div className="winsPart" style={{flex: this.props.wins}}>
                        {this.props.wins}
                    </div>
                    <div className="lossesPart" style={{flex: this.props.losses}}>
                        {this.props.losses}
                    </div>
                </div>
                <div className="WinRatio-text">
                    {winPercent}
                </div>
            </div>
        );
    }
}
export default WinRatio;
