import React, { Component } from 'react';
import { Link, withRouter } from 'react-router-dom';
import AppLogo from './AppLogo';
import './MainNavBar.css';
import SearchBar from './SearchBar';

class MainNavBar extends Component {
    render() {
        return (
            <div className="MainNavBar">
                <div className="_content">
                    <Link to="/"><AppLogo /></Link>
                    <Link to="/"><div>Leaderboard</div></Link>
                    <Link to="/recent_match_history"><div>Recent Matches</div></Link>
                    <Link to="/clans"><div>Clans</div></Link>
                    <div>
                        <SearchBar onChange={(val) => this.onChangePlayerSearch(val)}
                            placeholder="Player search..." />
                    </div>
                </div>
            </div>
        );
    }

    onChangePlayerSearch(val) {
        console.log("onChangePlayerSearch", val);
        this.props.history.push('/player/'+val);
    }
}

MainNavBar = withRouter(MainNavBar);
export default MainNavBar;
