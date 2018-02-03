import React, { Component } from 'react';
import './FlagIcon.css';

class FlagIcon extends Component {
    render() {
        let imgSrc;
        switch(this.props.flag) {
            case "EU":
                imgSrc = "flags/EU.gif";
                break;
            case "US":
                imgSrc = "flags/US.gif";
                break;
            case "AUS":
                imgSrc = "flags/AUS.gif";
                break;
            default:
                console.warn("Unrecognized flag", this.props.flag);
                imgSrc = "flags/EU.gif";
        }

        return (
            <img className="FlagIcon" src={imgSrc} alt={this.props.flag} />
        );
    }
}
export default FlagIcon;
