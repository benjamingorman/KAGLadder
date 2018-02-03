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
                <div className="_bar">
                    <div className="_wins" style={{flex: this.props.wins}}>
                        {this.props.wins}
                    </div>
                    <div className="_losses" style={{flex: this.props.losses}}>
                        {this.props.losses}
                    </div>
                </div>
                <div className="_text">
                    {winPercent}
                </div>
            </div>
        );
    }
}
export default WinRatio;
