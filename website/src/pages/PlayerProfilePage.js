import React, { Component } from 'react';
//import './PlayerProfilePage.css';
import PlayerProfile from '../components/PlayerProfile';
import Page from './Page';

class PlayerProfilePage extends Component {
    render() {
        return (
            <div className="PlayerProfilePage">
                <Page title="Player Profile">
                    <PlayerProfile username={this.props.match.params.username} />
                </Page>
            </div>
        );
    }
}
export default PlayerProfilePage;
