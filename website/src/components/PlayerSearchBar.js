import React from 'react';
import './PlayerSearchBar.css';
import Select from 'react-select';
import 'react-select/dist/react-select.css';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';

class PlayerSearchBar extends DynamicComponent {
    constructor(props) {
        super(props);
        this.state.username = "";
    }

    getEndpoints(props) {
        return {"playerNames": endpoints.playerNames()};
    }

    render() {
        let playerNames = this.getDynamicData("playerNames") || [];

        let options = [];
        for (let {username, nickname} of playerNames) {
            options.push({value: username, label: username});

            if (nickname)
                options.push({value: username, label: nickname});
        }

        const selectedValue = this.state.username;

        return (
            <div className="PlayerSearchBar">
                <Select
                    name="player-search-bar-text"
                    value={selectedValue}
                    onChange={this.handleChange.bind(this)}
                    options={options}
                    placeholder="Player search..."
                />
            </div>
        );
    }

    handleChange(valueObj) {
        //console.log("handleChange", valueObj) ;

        let username = "";
        if (valueObj) {
            username = valueObj.value;
        }

        this.setState({username: username});

        // Submit automatically on change
        if (this.props.onSubmit && this.validateUsername(username)) {
            this.props.onSubmit(username);
        }
        else {
            console.log("PlayerSearchBar: invalid username") ;
        }
    }

    validateUsername(username) {
        let playerNames = this.getDynamicData("playerNames") || [];

        if (playerNames.length > 0) {
            for (let i=0; i < playerNames.length; ++i) {
                if (playerNames[i].username === username)
                    return true;
            }
        }

        return false;
    }
}
export default PlayerSearchBar;
