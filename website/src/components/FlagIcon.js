import React, { Component } from 'react';
import './FlagIcon.css';

class FlagIcon extends Component {
    render() {
        let imgSrc;
        switch(this.props.flag) {
            case "EU":
                imgSrc = "flags/EU.png";
                break;
            case "US":
                imgSrc = "flags/US.png";
                break;
            case "AUS":
                imgSrc = "flags/AUS.png";
                break;
            default:
                console.warn("Unrecognized flag", this.props.flag);
                imgSrc = "flags/EU.png";
        }

        return (
            <img className="FlagIcon" src={imgSrc} alt={this.props.flag} />
        );
    }
}
export default FlagIcon;
